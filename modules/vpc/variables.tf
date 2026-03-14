variable "vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "create_tgw_default_route" {
  description = "If true, creates a 0.0.0.0/0 route in the private route tables pointing to the TGW."
  type        = bool
  default     = false
}

variable "tgw_id" {
  description = "The ID of the Transit Gateway to route to. Required if create_tgw_default_route is true."
  type        = string
  default     = null
}