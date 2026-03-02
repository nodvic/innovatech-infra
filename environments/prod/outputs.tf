output "hub_vpc_id" {
  value = module.hub_vpc.vpc_id
}

output "tgw_id" {
  value = module.transit_gateway.tgw_id
}