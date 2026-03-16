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
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
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

  user_data = <<-EOF
              #!/bin/bash
              # Log alle output naar een bestand (handig voor troubleshooten)
              exec > /var/log/user-data.log 2>&1

              # Wacht tot automatische Ubuntu-updates op de achtergrond klaar zijn
              while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done;

              # Voorkom interactieve prompts tijdens apt installaties
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y curl iptables iproute2 python3

              # Start de webserver direct op de achtergrond, zodat de poort bereikbaar is
              mkdir -p /var/www/vpn
              cd /var/www/vpn
              nohup python3 -m http.server 8080 > /dev/null 2>&1 &

              # Forceer de root map en HOME variabele
              cd /root
              export HOME=/root

              # Haal het publieke IP op via de AWS Metadata (voorkomt vastlopen bij IP detectie)
              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

              # Installeer OpenVPN automatisch
              curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
              chmod +x openvpn-install.sh
              export AUTO_INSTALL=y
              export APPROVE_IP=y
              export ENDPOINT=$PUBLIC_IP
              export CLIENT=client
              export PASS=1
              ./openvpn-install.sh
              
              # Kopieer het bestand naar de webserver map
              OVPN_FILE=$(find /root /home -maxdepth 2 -name "*.ovpn" 2>/dev/null | head -n 1)
              if [ -n "$OVPN_FILE" ]; then
                cp "$OVPN_FILE" /var/www/vpn/client.ovpn
                chmod 644 /var/www/vpn/client.ovpn
              fi

              # Stel de log beschikbaar voor troubleshooting als het tóch faalt
              cp /var/log/user-data.log /var/www/vpn/log.txt
              chmod 644 /var/www/vpn/log.txt
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "innovatech-openvpn-server"
  }
}