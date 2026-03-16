variable "vpc_id" {
  description = "VPC ID for the monitoring security group."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the monitoring instance."
  type        = string
}

variable "vpn_security_group_id" {
  description = "The Security Group ID of the VPN server allowed to access the monitoring tools."
  type        = string
}