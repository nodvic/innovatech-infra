module "hub_vpc" {
  source             = "../../modules/vpc"
  vpc_cidr           = "10.0.0.0/16"
  vpc_name           = "innovatech-hub-vpc"
  availability_zones = ["eu-central-1a"]
  public_subnets     = ["10.0.1.0/24"]
  private_subnets    = ["10.0.2.0/24"]
}

module "transit_gateway" {
  source         = "../../modules/networking"
  tgw_name       = "innovatech-tgw"
  hub_vpc_id     = module.hub_vpc.vpc_id
  hub_subnet_ids = module.hub_vpc.public_subnet_ids
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
  availability_zones = ["eu-central-1a"]
  public_subnets     = []
  private_subnets    = ["10.3.1.0/24"]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "data_vpc" {
  subnet_ids         = module.data_vpc.private_subnet_ids
  transit_gateway_id = module.transit_gateway.tgw_id
  vpc_id             = module.data_vpc.vpc_id

  tags = {
    Name = "tgw-attachment-data-vpc"
  }
}