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
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = var.subnet_ids[count.index]
  
  vpc_security_group_ids = [var.web_sg_ids[count.index]]

  user_data = <<-EOF
              #!/bin/bash
              sleep 15
              apt-get update
              apt-get install -y nginx stress
              systemctl enable nginx
              systemctl start nginx
              echo "Innovatech Webserver - Geautomatiseerd via Terraform" > /var/www/html/index.html
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "innovatech-webserver-${count.index + 1}"
  }
}