output "tgw_id" {
  value = aws_ec2_transit_gateway.this.id
}

output "tgw_default_route_table_id" {
  value = aws_ec2_transit_gateway.this.association_default_route_table_id
}

output "hub_vpc_attachment_id" {
  value = aws_ec2_transit_gateway_vpc_attachment.hub.id
}