
# ────────────────────────────── Locals ──────────────────────────────
locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
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
      path = "/devops/"
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


# ────────────────────────────── EKS Network Module ──────────────────────────────
module "eks_network" {
  source = "./modules/eks-network"

  region             = var.region
  vpc_cidr           = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  subnets = {
    public-1b      = { cidr_block = var.jenkins_subnet, availability_zone = "eu-north-1b", type = "public",  tier = "web" }
    private-db-1a  = { cidr_block = var.rds_subnets[0],  availability_zone = "eu-north-1a", type = "isolated", tier = "database" }
    private-db-1c  = { cidr_block = var.rds_subnets[1],  availability_zone = "eu-north-1c", type = "isolated", tier = "database-secondary" }
    private-eks-1a = { cidr_block = var.eks_subnets[0],  availability_zone = "eu-north-1a", type = "private", tier = "eks" }
    private-eks-1b = { cidr_block = var.eks_subnets[1],  availability_zone = "eu-north-1b", type = "private", tier = "eks" }
    private-eks-1c = { cidr_block = var.eks_subnets[2],  availability_zone = "eu-north-1c", type = "private", tier = "eks" }
  }

  nat_gateways = {
    nat-1b = {
      subnet_key = "public-1b"
      tags       = { AZ = "eu-north-1b" }
    }
  }


  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# Security Groups
# ═══════════════════════════════════════════════════════════════════════════════
module "sg" {
  source = "./modules/security-group"

  vpc_id = module.eks_network.vpc_id
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
      instance_type               = "t3.medium"
      subnet_id                   = module.eks_network.subnet_ids["public-1b"]
      security_group_ids          = [module.sg.security_group_ids["jenkins-sg"]]
      associate_public_ip_address = true
      user_data                   = local.jenkins_user_data
      root_volume_size            = 30
      tags                        = { Role = "jenkins-ci" }
    }
  }
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

      subnet_ids             = [module.eks_network.subnet_ids["private-db-1a"], module.eks_network.subnet_ids["private-db-1c"]]
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
# ECR (frontend and backend registrey)
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
#module "secrets" {
#  source = "./modules/secret-manager"
#
#  tags = local.tags
#
#  secrets = {
#    "${var.project_name}/db/credentials" = {
#      description             = "RDS master credentials for ${var.db_name}"
#      recovery_window_in_days = 7
#      secret_string = jsonencode({
#        username = var.db_username
#        password = var.db_password
#        dbname   = var.db_name
#        host     = module.rds.db_instance_addresses["app-db"]
#        port     = 5432
#        engine   = "postgres"
#      })
#      tags = { Tier = "database", Usage = "rds-credentials" }
#    }
#  }
#}



# ═══════════════════════════════════════════════════════════════════════════════
# EKS Setup
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
      Action = "sts:AssumeRole" # ← KEY: This allows "assuming" the role
      Principal = { Service = "eks.amazonaws.com" }  # ← WHO: EKS service
      # Think of it as: "EKS service has permission to BECOME this role"
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
                            module.eks_network.subnet_ids["private-eks-1a"],
                            module.eks_network.subnet_ids["private-eks-1b"],
                            module.eks_network.subnet_ids["private-eks-1c"]
                            ]
      kubernetes_version  = var.eks_kubernetes_version
      tags                = local.tags

      # Inject IAM roles created above
      cluster_role_arn    = module.eks_cluster_role.arn
      node_role_arn       = module.eks_node_role.arn

      # CRITICAL: Enable IRSA on the cluster
      enable_irsa         = true

      node_groups = {
        "default" = {
          subnet_ids     =  [
                            module.eks_network.subnet_ids["private-eks-1a"],
                            module.eks_network.subnet_ids["private-eks-1b"],
                            module.eks_network.subnet_ids["private-eks-1c"]
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
# IRSA Setup - MUST be after EKS cluster creation
# ═══════════════════════════════════════════════════════════════════════════════

# Wait for cluster to be fully created
resource "time_sleep" "wait_for_eks" {
  depends_on = [module.eks] # Wait for creation to START
  
  create_duration = "180s" # For OIDC to be available, Give it time to be READY
}

# Fetch cluster info AFTER it's created
# data are dynamic values that only exist AFTER creation
data "aws_eks_cluster" "this" {
  depends_on = [time_sleep.wait_for_eks]
  
  name = module.eks.cluster_name
}

# This gives you a SHORT-LIVED TOKEN (1 hour) to authenticate with K8s API, 
# dynamically generated by AWS
data "aws_eks_cluster_auth" "this" {
  depends_on = [time_sleep.wait_for_eks]
  
  name = module.eks.cluster_name
}


# Kubernetes provider - configure AFTER cluster exists
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
  
  # Use your region variable
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.this.name,
      "--region",
      var.region 
    ]
  }
}


# ═══════════════════════════════════════════════════════════════════════════════
# Kubernetes Namespaces
# ═══════════════════════════════════════════════════════════════════════════════

module "eks_namespaces" {
  depends_on = [time_sleep.wait_for_eks]
  source = "./modules/eks-namespace"
  
  namespaces = {
    # Platform namespaces
    argocd = {
      name = "argocd"
      labels = {
        category = "platform"
        tool     = "argocd"
      }
      annotations = {
        "owner" = "platform-team"
      }
    }
    
    observability = {
      name = "observability"
      labels = {
        category = "platform"
        tool     = "monitoring"
      }
      annotations = {
        "owner" = "sre-team"
      }
    }
    
    # Application namespaces
    backend = {
      name = "backend"
      labels = {
        category = "application"
        team     = "backend-team"
      }
      annotations = {
        "owner" = "backend-team"
      }
    }
    
    frontend = {
      name = "frontend"
      labels = {
        category = "application"
        team     = "frontend-team"
      }
      annotations = {
        "owner" = "frontend-team"
      }
    }
    
  }
  
  default_labels = {
    managed-by   = "terraform"
    environment  = var.environment
    cluster      = var.eks_cluster_name
  }
}


module "eks_irsa" {
  depends_on = [time_sleep.wait_for_eks, module.eks_namespaces]
  source       = "./modules/eks-irsa"
  cluster_name = module.eks.cluster_name
  
  # CRITICAL FIX: Pass the OIDC ISSUER URL, not ARN
  cluster_oidc_issuer = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  
  # Optional: Pass region if needed for tags
  region = var.region
  
  service_accounts = {
    backend = {
      role_name       = "${var.project_name}-${var.environment}-backend-irsa-role"
      policy_name     = "${var.project_name}-${var.environment}-backend-secrets-policy"
      policy_document = {
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
          Resource = "*"
        }]
      }
      namespace   = "backend"
      k8s_sa_name = "backend-sa"
    }

    alb_controller = {
      role_name       = "${var.project_name}-${var.environment}-alb-controller-irsa-role"
      policy_name     = "${var.project_name}-${var.environment}-alb-controller-policy"
      policy_document = {
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = [
            "ec2:Describe*", "elasticloadbalancing:*", "iam:CreateServiceLinkedRole",
            "iam:GetServerCertificate", "iam:ListServerCertificates",
            "cognito-idp:DescribeUserPoolClient",
            "waf-regional:GetWebACL", "waf-regional:GetWebACLForResource",
            "waf-regional:AssociateWebACL", "waf-regional:DisassociateWebACL",
            "wafv2:GetWebACL", "wafv2:GetWebACLForResource", "wafv2:AssociateWebACL", "wafv2:DisassociateWebACL",
            "shield:Get*", "shield:Describe*", "shield:CreateProtection", "shield:DeleteProtection"
          ]
          Resource = "*"
        }]
      }
      namespace   = "kube-system"
      k8s_sa_name = "aws-load-balancer-controller"
    }
  }
  
  tags = local.tags
}