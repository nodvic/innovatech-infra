variable "admin_email" {
  type = string
}

variable "db_password" {
  description = "Password for the database."
  type        = string
  sensitive   = true
}

variable "vpn_cidr_block" {
  description = "The CIDR block of the VPN network to allow access to the monitoring dashboard."
  type        = string
}