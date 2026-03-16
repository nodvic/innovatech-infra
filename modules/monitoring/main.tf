resource "aws_security_group" "monitoring_sg" {
  name        = "innovatech-monitoring-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    cidr_blocks     = [var.vpn_cidr_block]
  }

  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    cidr_blocks     = [var.vpn_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "innovatech-monitoring-sg"
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

resource "aws_instance" "monitoring" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y prometheus apt-transport-https software-properties-common wget unzip

              # Install Grafana
              mkdir -p /etc/apt/keyrings/
              wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
              echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list
              apt-get update
              apt-get install -y grafana

              # Install Loki
              LOKI_VERSION="2.9.1"
              wget https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip
              unzip loki-linux-amd64.zip
              mv loki-linux-amd64 /usr/local/bin/loki
              # Note: For a production setup, Loki would need a config file and a systemd service.

              # Enable and start services
              systemctl enable prometheus
              systemctl start prometheus
              systemctl enable grafana-server
              systemctl start grafana-server
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "innovatech-monitoring-server"
  }
}