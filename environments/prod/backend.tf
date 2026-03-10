terraform {
  backend "s3" {
    bucket         = "innovatech-terraform-state-vm" 
    key            = "prod/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
  }
}