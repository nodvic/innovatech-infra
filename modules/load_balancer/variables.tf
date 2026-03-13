variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "lb_security_group_id" {
  type = string
}

variable "web_instance_ips" {
  type = list(string)
}