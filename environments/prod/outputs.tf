output "vpc_id" {
  description = "The ID of the main VPC."
  value       = module.main_vpc.vpc_id
}

output "vpc_public_subnets" {
  description = "The public subnet IDs of the main VPC."
  value       = module.main_vpc.public_subnet_ids
}

output "vpc_private_subnets" {
  description = "The private subnet IDs of the main VPC."
  value       = module.main_vpc.private_subnet_ids
}

output "security_group_id" {
  description = "The ID of the main security group."
  value       = module.security.security_group_id
}

output "database_endpoint" {
  description = "The endpoint of the RDS database."
  value       = module.database.db_endpoint
}

output "web_instance_private_ips" {
  description = "The private IPs of the web server instances."
  value       = module.compute.instance_ips
}

output "monitoring_instance_private_ip" {
  description = "The private IP of the monitoring instance."
  value       = module.monitoring.monitoring_instance_ip
}