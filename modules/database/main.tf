resource "aws_security_group" "db_sg" {
  name        = "innovatech-db-sg"
  description = "Toegang tot database via poort 3306"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "data_subnet_group" {
  name_prefix = "innovatech-db-sng-"
  subnet_ids = var.private_subnet_ids

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "mysql_db" {
  allocated_storage    = 20
  db_name              = "innovatechdb"
  engine               = "mysql"
  engine_version       = "8.4.7"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.4"
  skip_final_snapshot  = true

  db_subnet_group_name   = aws_db_subnet_group.data_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  multi_az = false
}