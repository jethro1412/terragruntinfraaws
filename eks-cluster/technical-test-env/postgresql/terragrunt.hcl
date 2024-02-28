include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

include "stage" {
  path   = find_in_parent_folders("stage.hcl")
  expose = true
}

locals {
  # merge tags
  local_tags = {
    "Name" = "postgress-helm-chart"
  }

  tags = merge( include.stage.locals.tags, local.local_tags)
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
  helm_chart = {
    name             = "postgresql"
    namespace        = "postgresql"
    create_namespace = true
    repository       = "https://cetic.github.io/helm-charts"
    chart            = "postgresql"
    chart_version    = "0.2.5"
    values           = "${file("values.yaml")}"
    set = [{
      name : "controller.autoscaling.enabled",
      value : "true",
      type : "auto"
      }, {
      name : "defaultBackend.enabled",
      value : "true",
      type : "auto"
    }]
  }
}

terraform {
  source = "../../terraform-helper/helm_chart"
}