resource "aws_security_group" "vpn_sg" {
  name        = "innovatech-vpn-sg"
  description = "Security group voor de OpenVPN server"
  vpc_id      = var.vpc_id

  # OpenVPN poort (Wereldwijd open zodat je overal ter wereld kunt inloggen met de app)
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tijdelijke downloadpoort voor het .ovpn bestand (Alleen toegankelijk voor JOUW IP-adres!)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "vpn" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.vpn_sg.id]

  # LET OP: Terraform herkent geen <<-'HEREDOC' (bash-stijl quoted heredoc).
  # In plaats daarvan escapen we alle bash ${VAR} naar $${VAR} zodat
  # Terraform ze niet als HCL-interpolatie behandelt.
  user_data = <<-USERDATA
    #!/bin/bash
    set -euo pipefail
    exec > /var/log/user-data.log 2>&1

    # -------------------------------------------------------
    # FASE 0: Apt-lock afwachten en pakketten installeren
    # -------------------------------------------------------
    echo "[0/6] Wachten op apt-lock en pakketten installeren..."
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y openvpn easy-rsa curl iptables iproute2 python3

    # -------------------------------------------------------
    # Webserver starten zodat log.txt meteen bereikbaar is
    # -------------------------------------------------------
    mkdir -p /var/www/vpn
    ln -sf /var/log/user-data.log /var/www/vpn/log.txt
    (cd /var/www/vpn && nohup python3 -m http.server 8080 >/dev/null 2>&1 &)

    # -------------------------------------------------------
    # FASE 1: Publiek IP ophalen via AWS IMDSv2
    # -------------------------------------------------------
    echo "[1/6] Publiek IP ophalen via AWS metadata service (IMDSv2)..."
    IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
    PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
      "http://169.254.169.254/latest/meta-data/public-ipv4")

    if [ -z "$PUBLIC_IP" ]; then
      echo "[FOUT] Kon het publieke IP niet ophalen via IMDS. Script stopt."
      exit 1
    fi
    echo "[INFO] Publiek IP: $PUBLIC_IP"

    # -------------------------------------------------------
    # FASE 2: PKI initialiseren met EasyRSA
    # -------------------------------------------------------
    echo "[2/6] PKI initialiseren..."
    EASYRSA_DIR=/etc/openvpn/easy-rsa
    make-cadir "$EASYRSA_DIR"
    cd "$EASYRSA_DIR"

    export EASYRSA_BATCH=1
    export EASYRSA_REQ_CN="InnovatechVPN-CA"
    export EASYRSA_KEY_SIZE=2048
    export EASYRSA_CA_EXPIRE=3650
    export EASYRSA_CERT_EXPIRE=3650

    ./easyrsa init-pki

    # -------------------------------------------------------
    # FASE 3: Certificate Authority aanmaken
    # -------------------------------------------------------
    echo "[3/6] Certificate Authority aanmaken..."
    ./easyrsa build-ca nopass

    # -------------------------------------------------------
    # FASE 4: Server- en clientcertificaten + DH-params
    # -------------------------------------------------------
    echo "[4/6] Servercert, clientcert en DH-params aanmaken (duurt ~2 min)..."
    ./easyrsa build-server-full server nopass
    ./easyrsa build-client-full client nopass
    ./easyrsa gen-dh
    openvpn --genkey secret /etc/openvpn/ta.key

    # Kopieer sleutels naar /etc/openvpn
    cp pki/ca.crt             /etc/openvpn/ca.crt
    cp pki/issued/server.crt  /etc/openvpn/server.crt
    cp pki/private/server.key /etc/openvpn/server.key
    cp pki/dh.pem             /etc/openvpn/dh.pem

    # -------------------------------------------------------
    # FASE 5: Server configuratie schrijven
    # -------------------------------------------------------
    echo "[5/6] OpenVPN server configuratie schrijven..."
    cat > /etc/openvpn/server.conf <<SERVERCONF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 3
SERVERCONF

    # IP Forwarding en NAT inschakelen
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    NET_IF=$(ip route | awk '/^default/{print $5; exit}')
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$NET_IF" -j MASQUERADE
    iptables -A FORWARD -i tun0 -j ACCEPT
    iptables -A FORWARD -o tun0 -j ACCEPT

    # -------------------------------------------------------
    # FASE 6: Client .ovpn bestand samenstellen
    # -------------------------------------------------------
    echo "[6/6] Client .ovpn bestand aanmaken..."

    CA_CERT=$(cat /etc/openvpn/ca.crt)
    CLIENT_CERT=$(openssl x509 -in "$EASYRSA_DIR/pki/issued/client.crt")
    CLIENT_KEY=$(cat "$EASYRSA_DIR/pki/private/client.key")
    TLS_AUTH=$(cat /etc/openvpn/ta.key)

    # $${VAR} hieronder: dubbele $ zodat Terraform ze NIET interpoleert,
    # maar de bash-shell ze op runtime wél ziet als gewone $VAR.
    cat > /var/www/vpn/client.ovpn <<OVPNEOF
client
dev tun
proto udp
remote $${PUBLIC_IP} 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
key-direction 1
<ca>
$${CA_CERT}
</ca>
<cert>
$${CLIENT_CERT}
</cert>
<key>
$${CLIENT_KEY}
</key>
<tls-auth>
$${TLS_AUTH}
</tls-auth>
OVPNEOF

    chmod 644 /var/www/vpn/client.ovpn

    # OpenVPN server starten
    systemctl enable openvpn@server
    systemctl start openvpn@server

    echo "[SUCCESS] OpenVPN installatie voltooid! Download: http://$${PUBLIC_IP}:8080/client.ovpn"
  USERDATA

  user_data_replace_on_change = true

  tags = {
    Name = "innovatech-openvpn-server"
  }
}