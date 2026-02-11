
# ────────────────────────────── Locals ──────────────────────────────
locals {
  tags = {
    Project     = var.project_name
  }
}

# ────────────────────────────── EKS Network Module ──────────────────────────────
module "stand_alone_jenkins_network" {
  source = "../modules/eks-network"

  region             = var.region
  vpc_cidr           = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  subnets = {
    jenkins-public-1a      = {
      cidr_block = var.public_subnets[0], 
      availability_zone = "eu-north-1a", 
      type = "public",  
      tier = "stand-alone"
    }
  }

  nat_gateways = {}

  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# Security Groups
# ═══════════════════════════════════════════════════════════════════════════════
module "sg" {
  source = "../modules/security-group"

  vpc_id = module.stand_alone_jenkins_network.vpc_id
  tags   = local.tags

  security_groups = {
    stand-alone-jenkins-sg = {
      description = "Jenkins - SSH + web UI inbound; all outbound"
      ingress_rules = [
        { from_port = 22,   to_port = 22,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "SSH" },
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], description = "Jenkins web UI" },
      ]
      egress_rules = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], description = "All outbound" }
      ]
      tags = { Service = "jenkins" }
    }
  }

}

# ═══════════════════════════════════════════════════════════════════════════════
# EC2 – Jenkins (CI server outside cluster's VPC)
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────
# Jenkins Role to push to ECR 
# ───────────────────────────────

module "stand_alone_jenkins_ec2_role" {
  source = "../modules/iam-role"

  name        = "${var.project_name}-ec2-role"
  description = "IAM role for Jenkins EC2 to push to ECR and Secret Manager access"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.tags
}

module "stand_alone_jenkins_ec2_role_attach" {
  source    = "../modules/iam-role-policy-attachment"
  role_name = module.stand_alone_jenkins_ec2_role.name
  
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",  # Full ECR access
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",  # For build artifacts
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # For Full read/write access to secrets
  ]
}


module "ec2" {
  source = "../modules/ec2"

  tags = local.tags

  instances = {
    stand-alone-jenkins-server = {
      ami                         = var.ami_id
      instance_type               = "m7i-flex.large"
      subnet_id                   = module.stand_alone_jenkins_network.subnet_ids["jenkins-public-1a"]
      security_group_ids          = [module.sg.security_group_ids["stand-alone-jenkins-sg"]]
      associate_public_ip_address = true
      root_volume_size            = 30
      iam_role_name               = module.stand_alone_jenkins_ec2_role.name
      tags                        = { Role = "stand-alone-jenkins-ci" }
    }
  }
}

