module "hub_vpc" {
  source             = "../../modules/vpc"
  vpc_cidr           = "10.0.0.0/16"
  vpc_name           = "innovatech-hub-vpc"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  public_subnets     = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.2.0/24", "10.0.4.0/24"]
}

module "transit_gateway" {
  source         = "../../modules/networking"
  tgw_name       = "innovatech-tgw"
  hub_vpc_id     = module.hub_vpc.vpc_id
  hub_subnet_ids = module.hub_vpc.private_subnet_ids
}

module "app_vpc_1" {
  source             = "../../modules/vpc"
  vpc_cidr           = "10.1.0.0/16"
  vpc_name           = "innovatech-app-vpc-1"
  availability_zones = ["eu-central-1a"]
  public_subnets     = []
  private_subnets    = ["10.1.1.0/24"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app_vpc_1" {
  subnet_ids         = module.app_vpc_1.private_subnet_ids
  transit_gateway_id = module.transit_gateway.tgw_id
  vpc_id             = module.app_vpc_1.vpc_id

  tags = {
    Name = "tgw-attachment-app-vpc-1"
  }
}

module "app_vpc_2" {
  source             = "../../modules/vpc"
  vpc_cidr           = "10.2.0.0/16"
  vpc_name           = "innovatech-app-vpc-2"
  availability_zones = ["eu-central-1b"]
  public_subnets     = []
  private_subnets    = ["10.2.1.0/24"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app_vpc_2" {
  subnet_ids         = module.app_vpc_2.private_subnet_ids
  transit_gateway_id = module.transit_gateway.tgw_id
  vpc_id             = module.app_vpc_2.vpc_id

  tags = {
    Name = "tgw-attachment-app-vpc-2"
  }
}

module "data_vpc" {
  source             = "../../modules/vpc"
  vpc_cidr           = "10.3.0.0/16"
  vpc_name           = "innovatech-data-vpc"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  public_subnets     = []
  private_subnets    = ["10.3.1.0/24", "10.3.2.0/24"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "data_vpc" {
  subnet_ids         = module.data_vpc.private_subnet_ids
  transit_gateway_id = module.transit_gateway.tgw_id
  vpc_id             = module.data_vpc.vpc_id

  tags = {
    Name = "tgw-attachment-data-vpc"
  }
}

module "hub_security" {
  source   = "../../modules/security"
  vpc_id   = module.hub_vpc.vpc_id
  vpc_name = "hub"
}

module "app_vpc_1_security" {
  source   = "../../modules/security"
  vpc_id   = module.app_vpc_1.vpc_id
  vpc_name = "app-1"
}

module "app_vpc_2_security" {
  source   = "../../modules/security"
  vpc_id   = module.app_vpc_2.vpc_id
  vpc_name = "app-2"
}

module "database" {
  source              = "../../modules/database"
  private_subnet_ids  = module.data_vpc.private_subnet_ids
  vpc_id              = module.data_vpc.vpc_id
  allowed_cidr_blocks = ["10.1.0.0/16", "10.2.0.0/16"]
}

module "compute" {
  source     = "../../modules/compute"
  subnet_ids = [module.app_vpc_1.private_subnet_ids[0], module.app_vpc_2.private_subnet_ids[0]]
  web_sg_ids = [module.app_vpc_1_security.security_group_id, module.app_vpc_2_security.security_group_id]
}

module "load_balancer" {
  source                = "../../modules/load_balancer"
  vpc_id                = module.hub_vpc.vpc_id
  public_subnet_ids     = module.hub_vpc.public_subnet_ids
  lb_security_group_id  = module.hub_security.security_group_id
  web_instance_ips      = module.compute.instance_ips
}

module "monitoring" {
  source               = "../../modules/monitoring"
  vpc_id               = module.hub_vpc.vpc_id
  subnet_id            = module.hub_vpc.private_subnet_ids[0]
  lb_security_group_id = module.hub_security.security_group_id
}

module "soar" {
  source       = "../../modules/soar"
  vpc_id       = module.hub_vpc.vpc_id
  admin_email  = var.admin_email
  instance_ids = module.compute.instance_ids
}

resource "aws_route" "hub_to_app1" {
  route_table_id         = module.hub_vpc.public_route_table_id[0]
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = module.transit_gateway.tgw_id
}

resource "aws_route" "hub_to_app2" {
  route_table_id         = module.hub_vpc.public_route_table_id[0]
  destination_cidr_block = "10.2.0.0/16"
  transit_gateway_id     = module.transit_gateway.tgw_id
}

resource "aws_route" "app_1_to_hub" {
  route_table_id         = module.app_vpc_1.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.transit_gateway.tgw_id
}

resource "aws_route" "app_2_to_hub" {
  route_table_id         = module.app_vpc_2.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.transit_gateway.tgw_id
}

resource "aws_route" "hub_private_to_app1" {
  route_table_id         = module.hub_vpc.private_route_table_id
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = module.transit_gateway.tgw_id
}

resource "aws_route" "hub_private_to_app2" {
  route_table_id         = module.hub_vpc.private_route_table_id
  destination_cidr_block = "10.2.0.0/16"
  transit_gateway_id     = module.transit_gateway.tgw_id
}
