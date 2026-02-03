# ─── locals ─────────────────────────────────────────────────────────────────
locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# VPC
# ═══════════════════════════════════════════════════════════════════════════════
module "vpc" {
  source = "./modules/vpc"

  region               = var.region
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, { Name = "${var.project_name}-vpc" })
}

# ═══════════════════════════════════════════════════════════════════════════════
# Subnets
# ═══════════════════════════════════════════════════════════════════════════════
# Layout:
#   eu-north-1a  – 10.10.2.0/24 private  → RDS primary
#                – 10.10.3.0/24 private  → EKS
#   eu-north-1b  – 10.10.1.0/24 public   → Jenkins
#                – 10.10.4.0/24 private  → EKS
#                – 10.10.6.0/24 private  → RDS subnet group (required but unused)
#   eu-north-1c  – 10.10.5.0/24 private  → EKS
#
# Note: AWS requires DB subnet groups to span ≥2 AZs even for single-AZ instances

module "subnets" {
  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id

  subnets = {
    public-1b      = { cidr_block = var.jenkins_subnet, availability_zone = "eu-north-1b", tags = { Type = "public",  Tier = "web"      } }
    private-db-1a  = { cidr_block = var.rds_subnets[0], availability_zone = "eu-north-1a", tags = { Type = "private", Tier = "database" } }
    private-db-1c  = { cidr_block = var.rds_subnets[1], availability_zone = "eu-north-1c", tags = { Type = "private", Tier = "database-secondary" } }
    private-eks-1a = { cidr_block = var.eks_subnets[0], availability_zone = "eu-north-1a", tags = { Type = "private", Tier = "eks"      } }
    private-eks-1b = { cidr_block = var.eks_subnets[1], availability_zone = "eu-north-1b", tags = { Type = "private", Tier = "eks"      } }
    private-eks-1c = { cidr_block = var.eks_subnets[2], availability_zone = "eu-north-1c", tags = { Type = "private", Tier = "eks"      } }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Internet Gateway
# ═══════════════════════════════════════════════════════════════════════════════
module "igw" {
  source = "./modules/internet-gateway"

  region = var.region
  vpc_id = module.vpc.vpc_id

  tags = merge(local.tags, { Name = "${var.project_name}-igw" })
}

# ═══════════════════════════════════════════════════════════════════════════════
# NAT Gateway
# ═══════════════════════════════════════════════════════════════════════════════
#Terraform (AWS provider v5.x) only supports connectivity_type = "public" or "private" for aws_nat_gateway.
#"regional" is not a valid value for the AWS NAT Gateway API. There is no regional option you can pass directly. 
#The “regional” NAT gateway concept exists only in routing terms, not as a separate API parameter. 
#You still pick a subnet to place the NAT in, and AWS handles the rest.
#Terraform/AWS rejects it because the provider only accepts "public" or "private".

module "nat" { 
  source = "./modules/nat-gateway"

  region = var.region 
  vpc_id = module.vpc.vpc_id
  
  nat_gateways = { nat-1b = { 
      subnet_id = module.subnets.subnet_ids["public-1b"] 
      tags = { AZ = "eu-north-1b" } 
      }
    }
  }


# ═══════════════════════════════════════════════════════════════════════════════
# Route Tables
# ═══════════════════════════════════════════════════════════════════════════════
module "route_tables" {
  source = "./modules/route-table"

  region = var.region
  vpc_id = module.vpc.vpc_id

  route_tables = {
    public = {
      routes = [{ cidr_block = "0.0.0.0/0", gateway_id = module.igw.internet_gateway_id }]
      tags   = { Type = "public" }
    }
    private = {
      routes = [{ cidr_block = "0.0.0.0/0", nat_gateway_id = module.nat.nat_gateway_ids["nat-1b"] }]
      tags   = { Type = "private" }
    }
    database = {
      routes = []
      tags   = { Type = "private-isolated" }
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Route Table Associations
# ═══════════════════════════════════════════════════════════════════════════════
module "rt_assoc" {
  source = "./modules/route-table-association"

  region = var.region

  subnet_associations = {
    public-1b      = { subnet_id = module.subnets.subnet_ids["public-1b"],      route_table_id = module.route_tables.route_table_ids["public"]   }
    private-eks-1a = { subnet_id = module.subnets.subnet_ids["private-eks-1a"], route_table_id = module.route_tables.route_table_ids["private"]  }
    private-eks-1b = { subnet_id = module.subnets.subnet_ids["private-eks-1b"], route_table_id = module.route_tables.route_table_ids["private"]  }
    private-eks-1c = { subnet_id = module.subnets.subnet_ids["private-eks-1c"], route_table_id = module.route_tables.route_table_ids["private"]  }
    private-db-1a  = { subnet_id = module.subnets.subnet_ids["private-db-1a"],  route_table_id = module.route_tables.route_table_ids["database"] }
    private-db-1c  = { subnet_id = module.subnets.subnet_ids["private-db-1c"],  route_table_id = module.route_tables.route_table_ids["database"] }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Security Groups
# ═══════════════════════════════════════════════════════════════════════════════
module "sg" {
  source = "./modules/security-group"

  vpc_id = module.vpc.vpc_id
  tags   = local.tags

  security_groups = {
    eks-nodes-sg = {
      description = "EKS worker nodes - SSH inbound; all outbound"
      ingress_rules = [
        { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "SSH" }
      ]
      egress_rules = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], description = "All outbound" }
      ]
      tags = { Service = "eks" }
    }

    rds-sg = {
      description = "RDS - PostgreSQL from EKS Security Group only"
      ingress_rules = []
      egress_rules = []
      tags         = { Service = "rds" }
    }

    jenkins-sg = {
      description = "Jenkins - SSH + web UI inbound; all outbound"
      ingress_rules = [
        { from_port = 22,   to_port = 22,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "SSH" },
        { from_port = 8080, to_port = 8080, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Jenkins web UI" },
      ]
      egress_rules = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], description = "All outbound" }
      ]
      tags = { Service = "jenkins" }
    }
  }

}

# ═══════════════════════════════════════════════════════════════════════════════
# Security Group Rule – edit RDS ingress rule
# ═══════════════════════════════════════════════════════════════════════════════

module "sg-rules" {
  source = "./modules/security-group-rule"

  rules = {
    rds_from_eks = {
      type                     = "ingress"
      security_group_id        = module.sg.security_group_ids["rds-sg"]
      source_security_group_id = module.sg.security_group_ids["eks-nodes-sg"]

      from_port = 5432
      to_port   = 5432
      protocol  = "tcp"

      description = "PostgreSQL from EKS nodes only"
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EC2 – Jenkins (CI server outside cluster)
# ═══════════════════════════════════════════════════════════════════════════════
locals {
  jenkins_user_data = <<-SCRIPT
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl start docker && systemctl enable docker
    usermod -aG docker ec2-user

    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install java-11-openjdk -y
    yum install jenkins -y
    systemctl start jenkins && systemctl enable jenkins
  SCRIPT
}

module "ec2" {
  source = "./modules/ec2"

  tags = local.tags

  instances = {
    jenkins-server = {
      ami                         = var.ami_id
      instance_type               = "t3.micro"
      subnet_id                   = module.subnets.subnet_ids["public-1b"]
      security_group_ids          = [module.sg.security_group_ids["jenkins-sg"]]
      associate_public_ip_address = true
      user_data                   = local.jenkins_user_data
      root_volume_size            = 30
      tags                        = { Role = "jenkins-ci" }
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EKS (ArgoCD for CD will be deployed as pods in cluster later)
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────
# EKS Cluster IAM Role
# ───────────────────────────────
module "eks_cluster_role" {
  source = "./modules/iam-role"

  name        = "${var.eks_cluster_name}-cluster-role"
  description = "EKS Cluster IAM Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = local.tags
}

module "eks_cluster_role_attach" {
  source    = "./modules/iam-role-policy-attachment"
  role_name = module.eks_cluster_role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ]
}

# ───────────────────────────────
# Node Group IAM Role
# ───────────────────────────────
module "eks_node_role" {
  source = "./modules/iam-role"

  name        = "${var.eks_cluster_name}-node-group-role"
  description = "EKS Node Group IAM Role"
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

module "eks_node_role_attach" {
  source    = "./modules/iam-role-policy-attachment"
  role_name = module.eks_node_role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

# ───────────────────────────────
# EKS Cluster + Node Groups
# ───────────────────────────────
module "eks" {
  source = "./modules/eks"

  clusters = {
    "${var.eks_cluster_name}" = {
      subnet_ids          = [
                            module.subnets.subnet_ids["private-eks-1a"],
                            module.subnets.subnet_ids["private-eks-1b"],
                            module.subnets.subnet_ids["private-eks-1c"]
                            ]
      kubernetes_version  = var.eks_kubernetes_version
      tags                = local.tags

      # Inject IAM roles created above
      cluster_role_arn    = module.eks_cluster_role.arn
      node_role_arn       = module.eks_node_role.arn

      node_groups = {
        "default" = {
          subnet_ids     =  [
                            module.subnets.subnet_ids["private-eks-1a"],
                            module.subnets.subnet_ids["private-eks-1b"],
                            module.subnets.subnet_ids["private-eks-1c"]
                            ]
          desired_size   = var.eks_node_count
          min_size       = var.eks_node_count
          max_size       = var.eks_node_count
          instance_types = [var.eks_node_instance_type]
          disk_size      = var.eks_node_disk_size
        }
      }
    }
  }

  tags = local.tags
}



# ═══════════════════════════════════════════════════════════════════════════════
# RDS (Single-AZ for free tier, but subnet group spans 2 AZs per AWS requirement)
# ═══════════════════════════════════════════════════════════════════════════════
module "rds" {
  source = "./modules/rds"

  region = var.region
  tags   = local.tags

  db_instances = {
    app-db = {
      engine            = "postgres"
      engine_version    = "14.15"
      instance_class    = "db.t3.micro"
      allocated_storage = 20
      username          = var.db_username
      password          = var.db_password
      db_name           = var.db_name
      port              = 5432

      subnet_ids             = [module.subnets.subnet_ids["private-db-1a"], module.subnets.subnet_ids["private-db-1c"]]
      vpc_security_group_ids = [module.sg.security_group_ids["rds-sg"]]

      multi_az                 = false
      availability_zone        = "eu-north-1a"
      storage_type             = "gp3"
      storage_encrypted        = true
      backup_retention_period  = 0
      skip_final_snapshot      = true
      deletion_protection      = false
      delete_automated_backups = true

      tags = { Tier = "database" }
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ECR (frontend and backend only)
# ═══════════════════════════════════════════════════════════════════════════════
module "ecr" {
  source = "./modules/ecr"

  region = var.region
  tags   = local.tags

  repositories = {
    "${var.project_name}-frontend" = { image_tag_mutability = "MUTABLE", scan_on_push = true, force_delete = true, tags = { Component = "frontend" } }
    "${var.project_name}-backend"  = { image_tag_mutability = "MUTABLE", scan_on_push = true, force_delete = true, tags = { Component = "backend"  } }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Secrets Manager (for RDS and K8s secrets)
# ═══════════════════════════════════════════════════════════════════════════════
module "secrets" {
  source = "./modules/secret-manager"

  tags = local.tags

  secrets = {
    "${var.project_name}/db/credentials" = {
      description             = "RDS master credentials for ${var.db_name}"
      recovery_window_in_days = 7
      secret_string = jsonencode({
        username = var.db_username
        password = var.db_password
        dbname   = var.db_name
        host     = module.rds.db_instance_addresses["app-db"]
        port     = 5432
        engine   = "postgres"
      })
      tags = { Tier = "database", Usage = "rds-credentials" }
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# IAM – DevOps Engineers
# ═══════════════════════════════════════════════════════════════════════════════
module "iam_policy_admin" {
  source = "./modules/iam-policy"

  policies = {
    "AdminAccess" = {
      description = "Administrator access for DevOps Engineers"
      policy_document = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = "*"
          Resource = "*"
        }]
      })
      tags = { Team = "devops" }
    }
  }

  tags = local.tags
}

module "iam_group" {
  source = "./modules/iam-group"

  groups = {
    "DevOps-Engineers" = {
      path = "/devops/"
      tags = { Team = "devops" }
    }
  }
}

module "iam_group_policy_attachment" {
  source = "./modules/iam-group-policy-attachment"

  attachments = {
    "devops-admin-attach" = {
      group = module.iam_group.group_names["DevOps-Engineers"]
      policy_arn = module.iam_policy_admin.policy_arns["AdminAccess"]
    }
  }
}

module "iam_users" {
  source = "./modules/iam-user"

  users = {
    "Alpha-DevOps-Eng" = {
      path          = "/devops/"
      force_destroy = true
      tags          = { Team = "devops", Engineer = "alpha" }
    }
    "Sigma-DevOps-Eng" = {
      path          = "/devops/"
      force_destroy = true
      tags          = { Team = "devops", Engineer = "sigma" }
    }
  }

  tags = local.tags
}

module "iam_user_group_membership" {
  source = "./modules/iam-user-group-membership"

  memberships = {
    "alpha-devops-membership" = {
      user   = module.iam_users.user_names["Alpha-DevOps-Eng"]
      groups = [module.iam_group.group_names["DevOps-Engineers"]]
    }
    "sigma-devops-membership" = {
      user   = module.iam_users.user_names["Sigma-DevOps-Eng"]
      groups = [module.iam_group.group_names["DevOps-Engineers"]]
    }
  }
}
