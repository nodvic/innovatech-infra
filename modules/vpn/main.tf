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
              # Installeer OpenVPN automatisch
              curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
              chmod +x openvpn-install.sh
              export AUTO_INSTALL=y
              ./openvpn-install.sh
              
              # Maak het configuratiebestand veilig beschikbaar via een interne webserver
              mkdir -p /var/www/vpn
              cp /root/client.ovpn /var/www/vpn/client.ovpn
              cd /var/www/vpn
              nohup python3 -m http.server 8080 > /dev/null 2>&1 &
              EOF

  tags = {
    Name = "innovatech-openvpn-server"
  }
}