terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 4.17.0, <= 5.0.0"
    }
  }
}

# Helper for creating AWS KMS 
resource "aws_kms_key" "eks" {
  description             = var.aws_kms_key.description
  deletion_window_in_days = var.aws_kms_key.deletion_window_in_days
  enable_key_rotation     = var.aws_kms_key.enable_key_rotation
  tags                    = var.aws_kms_key.tags
}

# Helper for creating Security Group

resource "aws_security_group" "additional_security_group" {
  name_prefix = var.aws_security_group.name_prefix
  vpc_id      = var.aws_security_group.vpc_id

  dynamic "ingress" {
    for_each = var.aws_security_group.ingresses
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  tags = var.aws_security_group.tags
}

# EKS Module 

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.5.1"
  # Define cluster basic configuration
  cluster_name                    = var.eks.cluster_name
  cluster_version                 = var.eks.cluster_version
  cluster_endpoint_private_access = var.eks.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.eks.cluster_endpoint_public_access
 
  # Define cluster addon
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
  }
    # Define Cluster encryption
  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]
  # Define 
  vpc_id     = var.eks.vpc_id
  subnet_ids = var.eks.subnets

  # Extend cluster security group rules
  cluster_security_group_additional_rules = var.eks.cluster_security_group_additional_rules

  # Extend node-to-node security group rules
  node_security_group_additional_rules = var.eks.node_security_group_additional_rules

  eks_managed_node_group_defaults = {
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = var.eks.eks_managed_node_groups

  tags = var.eks.tags
}


module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  role_name_prefix      = var.vpc_cni_irsa.role_name_prefix
  attach_vpc_cni_policy = var.vpc_cni_irsa.attach_vpc_cni_policy
  vpc_cni_enable_ipv4   = var.vpc_cni_irsa.vpc_cni_enable_ipv4

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = var.eks.tags
}

