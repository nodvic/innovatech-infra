output "hub_vpc_id" {
  value = module.hub_vpc.vpc_id
}

output "tgw_id" {
  value = module.transit_gateway.tgw_id
}

output "app_vpc_1_id" {
  value = module.app_vpc_1.vpc_id
}

output "app_vpc_2_id" {
  value = module.app_vpc_2.vpc_id
}

output "data_vpc_id" {
  value = module.data_vpc.vpc_id
}

output "hub_sg_id" {
  value = module.hub_security.security_group_id
}

output "app_vpc_1_sg_id" {
  value = module.app_vpc_1_security.security_group_id
}