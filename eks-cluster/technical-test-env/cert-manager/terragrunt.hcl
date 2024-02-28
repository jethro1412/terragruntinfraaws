include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

include "stage" {
  path   = find_in_parent_folders("stage.hcl")
  expose = true
}

locals {
  local_tags = {
    "Name" = "helm-chart-cert-manager"
  }

  tags = merge(local.local_tags)
}

dependency "eks_cluster" {
  config_path                             = "../eks"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    eks_cluster_name     = "some_name"
    eks_cluster_endpoint = "some_id"
    eks_cluster_ca_cert  = "some-cert"
  }
}

generate "provider_global" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {}
  required_version = "${include.env.locals.version_terraform}"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "${include.env.locals.version_provider_aws}"
    }
    helm = {
      source = "hashicorp/helm"
      version = "${include.env.locals.version_provider_helm}"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "aws" {
  region = "${include.env.locals.region}"
}

provider "helm" {
  kubernetes {
    host                   = "${dependency.eks_cluster.outputs.eks_cluster_endpoint}"
    cluster_ca_certificate = base64decode("${dependency.eks_cluster.outputs.eks_cluster_ca_cert}")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", "${dependency.eks_cluster.outputs.eks_cluster_name}"]
    }
  }
}

provider "kubectl" {
  host                   = "${dependency.eks_cluster.outputs.eks_cluster_endpoint}"
  cluster_ca_certificate = base64decode("${dependency.eks_cluster.outputs.eks_cluster_ca_cert}")
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "${dependency.eks_cluster.outputs.eks_cluster_name}"]
  }
}
EOF
}

inputs = {
  cert_manager_helm_chart = {
    name             = "cert-manager"
    namespace        = "cert-manager"
    create_namespace = true
    repository       = "https://charts.jetstack.io"
    chart            = "cert-manager"
    chart_version    = "1.10.0"
    values           = "${file("values.yaml")}"
    set              = []
  }
}

terraform {
  source = "../../terraform-helper/cert-manager"
}