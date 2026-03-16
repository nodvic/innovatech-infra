output "monitoring_instance_ip" {
  description = "The private IP of the monitoring instance."
  value = aws_instance.monitoring.private_ip
}