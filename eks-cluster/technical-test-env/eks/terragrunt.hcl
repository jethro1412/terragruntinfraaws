include {
  path = find_in_parent_folders()
}


dependency "vpc" {
  config_path                             = "../vpc"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    vpc_id                  = "some_id"
    vpc_private_subnets_ids = ["some-id"]
    vpc_public_subnets_ids  = ["some-id"]
  }
}

inputs = {
  aws_kms_key = {
    description             = "AWS EKS KMS Encryption Key"
    deletion_window_in_days = 7
    enable_key_rotation     = true
  }

  aws_security_group = {
    name_prefix = "eks-cluster-additional-sg"
    vpc_id      = dependency.vpc.outputs.vpc_id
    ingresses = [{
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
      cidr_blocks = [
        "10.10.96.0/20"
      ]
    }]
  }


  eks = {
    cluster_name                    = "tech-test-cluster"
    cluster_version                 = "1.29"
    cluster_endpoint_private_access = true
    cluster_endpoint_public_access  = true
    vpc_id                          = dependency.vpc.outputs.vpc_id
    subnets                         = dependency.vpc.outputs.vpc_public_subnets_ids
    cluster_security_group_additional_rules = {
      egress_nodes_ephemeral_ports_tcp = {
        description                = "To node 1025-65535"
        protocol                   = "tcp"
        from_port                  = 1025
        to_port                    = 65535
        type                       = "egress"
        source_node_security_group = true
      }
    }
    node_security_group_additional_rules = {
      ingress_self_all = {
        description = "Node to node all ports/protocols"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "ingress"
        self        = true
      }
      egress_all = {
        description      = "Node all egress"
        protocol         = "-1"
        from_port        = 0
        to_port          = 0
        type             = "egress"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
      }
    }
    eks_managed_node_groups = {
      default_node_group_1 = {
        create_launch_template = false
        launch_template_name   = ""

        disk_size = 50

        min_size     = 1
        max_size     = 3
        desired_size = 1

        capacity_type        = "SPOT"
        force_update_version = true
        instance_types       = ["t3.small"]
        taints               = []
      }
      default_node_group_2 = {
        create_launch_template = false
        launch_template_name   = ""

        disk_size = 50

        min_size     = 1
        max_size     = 7
        desired_size = 1

        capacity_type        = "SPOT"
        force_update_version = true
        instance_types       = ["t3.micro"]

        labels = {
          NodeTypeClass = "spot-instance"
        }

        taints = [{
          key    = "dedicated"
          value  = "spot"
          effect = "NO_SCHEDULE"
          }
        ]
      }
    }
  }
  vpc_cni_irsa = {
    role_name_prefix      = "irsa-vpc-cni"
    attach_vpc_cni_policy = true
    vpc_cni_enable_ipv4   = true
  }
}

terraform  {
    source = "../../terraform-helper/aws_eks_cluster"
  }