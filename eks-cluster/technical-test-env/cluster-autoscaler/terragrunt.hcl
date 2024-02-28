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
    "Name" = "cluster-autoscaler"
  }

  tags = merge( include.stage.locals.tags, local.local_tags)
}

terraform {
  source = "../terraform-helper/cluster_autoscaler_helm_chart"
}

dependency "eks_cluster" {
  config_path                             = "../eks"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    eks_cluster_name      = "some_name"
    eks_cluster_id        = "some-id"
    eks_cluster_endpoint  = "some-endpoint"
    eks_cluster_ca_cert   = "some-cert"
    eks_oidc_provider_arn = "some-arn"
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
EOF
}

inputs = {
  cluster_autoscaler_irsa = {
    role_name_prefix                 = "cluster-autoscaler"
    role_description                 = "IRSA role for cluster autoscaler"
    attach_cluster_autoscaler_policy = true
    cluster_autoscaler_cluster_ids   = dependency.eks_cluster.outputs.eks_cluster_id
    eks_provider_arn                 = dependency.eks_cluster.outputs.eks_oidc_provider_arn
  }

  cluster_autoscaler_helm_chart = {
    name             = "autoscaler"
    namespace        = "kube-system"
    create_namespace = false
    repository       = "https://kubernetes.github.io/autoscaler"
    chart            = "cluster-autoscaler"
    chart_version    = "9.21.0"
    values           = "${file("values.yaml")}"
    set = [{
      name : "autoDiscovery.clusterName",
      value : "${dependency.eks_cluster.outputs.eks_cluster_name}",
      type : "string"
      }, {
      name : "awsRegion",
      value : "${include.env.locals.region}",
      type : "string"
      }, {
      name : "rbac.serviceAccount.name",
      value : "cluster-autoscaler-aws",
      type : "string"
    }]
  }
}

