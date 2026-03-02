module "hub_vpc" {
  source             = "../../modules/vpc"
  vpc_cidr           = "10.0.0.0/16"
  vpc_name           = "innovatech-hub-vpc"
  availability_zones = ["eu-central-1a"]
  public_subnets     = ["10.0.1.0/24"]
  private_subnets    = ["10.0.2.0/24"]
}