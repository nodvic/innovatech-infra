variable "private_subnet_ids" {
  description = "List of private subnet IDs for the database."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the database security group."
  type        = string
}

variable "source_security_group_id" {
  description = "The ID of the security group that is allowed to access the database."
  type        = string
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

variable "db_name" {
  description = "The name of the database."
  type        = string
  default     = "innovatechdb"
}

variable "instance_class" {
  description = "The instance class for the database."
  type        = string
  default     = "db.t3.micro"
}