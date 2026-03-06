resource "aws_db_subnet_group" "data_subnet_group" {
  name       = "innovatech-data-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "mysql_db" {
  allocated_storage    = 20
  db_name              = "innovatechdb"
  engine               = "mysql"
  engine_version       = "8.4.7"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "Wachtwoord123!"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true

  db_subnet_group_name   = aws_db_subnet_group.data_subnet_group.name
  vpc_security_group_ids = [var.db_sg_id]

  multi_az = false
}