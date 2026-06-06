provider "aws" {
  region = "ap-south-1"
}

module "alb" {
  source = "./modules/alb"

  alb_name          = "my-alb"
  vpc_id            = var.vpc_id
  subnet_ids        = var.public_subnets
  security_group_id = var.security_group_id
}