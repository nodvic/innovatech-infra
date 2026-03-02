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