variable "tgw_name" {
  type = string
}

variable "hub_vpc_id" {
  type = string
}

variable "hub_subnet_ids" {
  type = list(string)
}