include {
  path = find_in_parent_folders()
}

locals {
  local_tags = {
    "Name" = "eks-techtest-vpc"
  }

  tags = merge(  local.local_tags)
}



terraform {
  source = "../../terraform-helper/vpc"
  extra_arguments "bucket" {
    commands = get_terraform_commands_that_need_vars()
    optional_var_files = [
      find_in_parent_folders("region.tfvars", "ignore"),
      find_in_parent_folders("env.tfvars", "ignore"),
    ]
  }
}

inputs = {
  vpc_subnet_module = {
    name                 = "eks-vpc-techtest"
    version              = "~>3.19.0"
    cidr_block           = "10.10.96.0/20"
    private_subnets      = ["10.10.96.0/22", "10.10.100.0/22"]
    public_subnets       = ["10.10.104.0/22", "10.10.108.0/22"]
    enable_ipv6          = false
    enable_nat_gateway   = true
    enable_vpn_gateway   = false
    enable_dns_hostnames = true
    enable_dns_support   = true
  }
  tags = local.tags
}

