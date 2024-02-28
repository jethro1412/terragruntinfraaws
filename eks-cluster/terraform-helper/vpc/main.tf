data "aws_availability_zones" "available" {}


terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 4.17.0, <= 5.0.0"
    }
  }
}

locals {
    azs = data.aws_availability_zones.available.names
}

module "vpc_subnet_module" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = var.vpc_subnet_module.name
  cidr = var.vpc_subnet_module.cidr_block

  azs             = var.vpc_subnet_module.azs
  private_subnets = var.vpc_subnet_module.private_subnets
  public_subnets  = var.vpc_subnet_module.public_subnets

  enable_nat_gateway   = var.vpc_subnet_module.enable_nat_gateway
  enable_vpn_gateway   = var.vpc_subnet_module.enable_vpn_gateway
  enable_dns_hostnames = var.vpc_subnet_module.enable_dns_hostnames
  enable_dns_support   = var.vpc_subnet_module.enable_dns_support
  
  tags = var.tags
  

  
}