resource "aws_ec2_transit_gateway" "this" {
  description = "Transit Gateway voor Innovatech netwerkarchitectuur"
  
  tags = {
    Name = var.tgw_name
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  subnet_ids         = var.hub_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = var.hub_vpc_id

  tags = {
    Name = "${var.tgw_name}-hub-attachment"
  }
}

resource "aws_ec2_transit_gateway_route" "internet_egress" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.this.association_default_route_table_id
}