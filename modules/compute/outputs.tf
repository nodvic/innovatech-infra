output "instance_ips" {
  value = aws_instance.web[*].private_ip
}