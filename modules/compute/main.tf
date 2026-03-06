resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0084a47cc718c111a"
  instance_type = "t2.micro"
  subnet_id     = var.subnet_ids[count.index]
  
  vpc_security_group_ids = [var.web_sg_ids[count.index]]

  tags = {
    Name = "innovatech-webserver-${count.index + 1}"
  }
}