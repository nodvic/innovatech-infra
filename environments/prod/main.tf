module "main_vpc" {
  source             = "../../modules/vpc"
  vpc_cidr           = "10.0.0.0/16"
  vpc_name           = "innovatech-main-vpc"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  public_subnets     = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.2.0/24", "10.0.4.0/24"]
}

module "security" {
  source   = "../../modules/security"
  vpc_id   = module.main_vpc.vpc_id
  vpc_name = "main"
}

module "database" {
  source              = "../../modules/database"
  private_subnet_ids  = module.main_vpc.private_subnet_ids
  vpc_id              = module.main_vpc.vpc_id
  source_security_group_id = module.security.security_group_id
  db_password              = var.db_password
}

module "compute" {
  source     = "../../modules/compute"
  subnet_ids = module.main_vpc.private_subnet_ids
  web_sg_ids = [module.security.security_group_id]
}

module "load_balancer" {
  source                = "../../modules/load_balancer"
  vpc_id                = module.main_vpc.vpc_id
  public_subnet_ids     = module.main_vpc.public_subnet_ids
  lb_security_group_id  = module.security.security_group_id
  web_instance_ips      = module.compute.instance_ips
}

module "vpn" {
  source           = "../../modules/vpn"
  vpc_id           = module.main_vpc.vpc_id
  subnet_id        = module.main_vpc.public_subnet_ids[0]
  admin_cidr_block = var.vpn_cidr_block
}

module "monitoring" {
  source               = "../../modules/monitoring"
  vpc_id               = module.main_vpc.vpc_id
  subnet_id            = module.main_vpc.private_subnet_ids[0]
  vpn_security_group_id = module.vpn.security_group_id
}

module "soar" {
  source       = "../../modules/soar"
  vpc_id       = module.main_vpc.vpc_id
  admin_email  = var.admin_email
  instance_ids = module.compute.instance_ids
}
