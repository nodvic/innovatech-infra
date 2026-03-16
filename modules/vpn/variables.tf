variable "vpc_id" {
  description = "De VPC ID waar de VPN in wordt geplaatst."
  type        = string
}

variable "subnet_id" {
  description = "Het publieke subnet ID voor de VPN server."
  type        = string
}

variable "admin_cidr_block" {
  description = "Jouw eigen IP-adres om het configuratiebestand veilig te kunnen downloaden."
  type        = string
}