variable "vpc_id" {
  description = "VPC ID for the monitoring security group."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the monitoring instance."
  type        = string
}

variable "vpn_cidr_block" {
  description = "The CIDR block of the VPN network allowed to access the monitoring tools."
  type        = string
}