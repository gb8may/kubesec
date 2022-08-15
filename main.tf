module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = var.vpc_name
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  create_egress_only_igw          = true

  public_subnet_ipv6_prefixes  = [0, 1, 2]
  private_subnet_ipv6_prefixes = [3, 4, 5]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
}

resource "aws_kms_key" "kubesec-cluster" {
  description             = "Cluster key"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "kubesec-cluster-alias" {
  name          = "alias/KubeSec-Cluster"
  target_key_id = aws_kms_key.kubesec-cluster.key_id
}

resource "aws_kms_key" "kubesec-ebs" {
  description             = "EBS key"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "kubesec-ebs-alias" {
  name          = "alias/KubeSec-EBS"
  target_key_id = aws_kms_key.kubesec-ebs.key_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  tags = {
    Environment = "DevOps"
    Name        = "${var.cluster_name}"
  }

  cluster_encryption_config = [
    {
      provider_key_arn = "${aws_kms_key.kubesec-cluster.arn}"
      resources        = ["secrets"]
    }
  ]

  eks_managed_node_group_defaults = {
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"

        ebs = {
          volume_size = "20"
          volume_type = "gp3"
          encrypted   = true
          kms_key_id  = "${aws_kms_key.kubesec-ebs.arn}"
        }

      }
    }
  }
    
  eks_managed_node_groups = [
    {
      asg_desired_capacity      = 2
      asg_max_capacity          = 3
      asg_min_capacity          = 2
      instance_type             = "${var.wg1_instance_type}"
      name                      = "${var.wg1_name}"
      kubelet_extra_args        = "--node-labels=role=kubesec"
      create_launch_template = false
      launch_template_name   = ""
    },
  ]
 }