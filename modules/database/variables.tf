variable "private_subnet_ids" {
  description = "List of private subnet IDs for the database."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the database security group."
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database."
  type        = list(string)
}

variable "db_username" {
  description = "Database admin username."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database admin password."
  type        = string
  sensitive   = true
}