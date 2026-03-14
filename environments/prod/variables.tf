variable "admin_email" {
  type = string
}

variable "db_password" {
  description = "Password for the database."
  type        = string
  sensitive   = true
}