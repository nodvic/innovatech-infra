output "security_group_id" {
  value = aws_security_group.vpn_sg.id
}

output "vpn_public_ip" {
  value = aws_instance.vpn.public_ip
}