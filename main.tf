
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
    # The Next 3 subnets are for Jenkins Server "in public-1b" & ALB "as it requires a public subnet in each AZ your nodes are in"
    public-1a      = {
      cidr_block = var.public_subnets[0], 
      availability_zone = "eu-north-1a", 
      type = "public",  
      tier = "alb", 
      tags = { # Extra tags Required for alb
        "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
        "kubernetes.io/role/elb" = "1"   # ← For ELBs
      } 
    }

    public-1b      = { 
      cidr_block = var.public_subnets[1], 
      availability_zone = "eu-north-1b", 
      type = "public",  
      tier = "alb-and-jenkins", 
      tags = { # Extra tags Required for alb
        "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
        "kubernetes.io/role/elb" = "1"  # ← For ELBs
      } 
    }

    public-1c      = { 
      cidr_block = var.public_subnets[2], 
      availability_zone = "eu-north-1c", 
      type = "public",  
      tier = "alb", 
      tags = { # Extra tags Required for alb
        "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
        "kubernetes.io/role/elb" = "1"  # ← For ELBs
      } 
    }

    # The next 2 private subnets are for RDS, one where it's physically created and other is for RDS requirements Because :
    # the DB subnet group is meant to provide high-availability placement options if you later enable Multi-AZ, 
    # or for internal networking requirements
    private-db-1a  = { 
      cidr_block = var.rds_subnets[0],  
      availability_zone = "eu-north-1a", 
      type = "isolated", 
      tier = "database" 
    }

    private-db-1c  = { 
      cidr_block = var.rds_subnets[1],  
      availability_zone = "eu-north-1c", 
      type = "isolated", 
      tier = "database-secondary" 
    }

    # The next 3 private subnets are for the cluster
    private-eks-1a = { 
      cidr_block = var.eks_subnets[0],  
      availability_zone = "eu-north-1a", 
      type = "private", 
      tier = "eks", 
      tags = {
        "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb" = "1"  # ← For internal ELBs
      }
    }

    private-eks-1b = { 
      cidr_block = var.eks_subnets[1],  
      availability_zone = "eu-north-1b", 
      type = "private", 
      tier = "eks", 
      tags = {
        "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb" = "1"  # ← For internal ELBs
      }
    }

    private-eks-1c = { 
      cidr_block = var.eks_subnets[2],  
      availability_zone = "eu-north-1c", 
      type = "private", 
      tier = "eks", 
      tags = {
        "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb" = "1"  # ← For internal ELBs
      }
    }

  }

  # Creating one NAT Gateway for public subnets, placed in in "public-1b" public subnet so all public subnets can connect to it 
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
    rds-sg = {
      description = "RDS - PostgreSQL from EKS Security Group only"
      ingress_rules = [] # We'll add the rule via sg-rules module to only accept traffic from the later created node group sg by EKS node group
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
# EC2 – Jenkins (CI server outside cluster)
# ═══════════════════════════════════════════════════════════════════════════════

locals {
  # a script to install Jenkins on it's EC2 instance
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

# ──────────────────────────────────────────────────────────────
# Jenkins Role to push to ECR and ECR access
# ──────────────────────────────────────────────────────────────

module "jenkins_ec2_role" {
  source = "./modules/iam-role"

  name        = "${var.project_name}-jenkins-ec2-role"
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

module "jenkins_ec2_role_attach" {
  source    = "./modules/iam-role-policy-attachment"
  role_name = module.jenkins_ec2_role.name
  
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",  # Full ECR access
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",  # For build artifacts
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # For Full read/write access to secrets
  ]
}


module "ec2" {
  source = "./modules/ec2"

  tags = local.tags

  instances = {
    jenkins-server = {
      ami                         = var.ami_id
      instance_type               = "m7i-flex.large"
      subnet_id                   = module.eks_network.subnet_ids["public-1b"]
      security_group_ids          = [module.sg.security_group_ids["jenkins-sg"]]
      associate_public_ip_address = true
      user_data                   = local.jenkins_user_data
      root_volume_size            = 30
      iam_role_name               = module.jenkins_ec2_role.name
      tags                        = { Role = "jenkins-ci" }
    }
  }
}


# ═══════════════════════════════════════════════════════════════════════════════
# RDS (Single-AZ, but subnet group spans 2 AZs per AWS requirement)
# ═══════════════════════════════════════════════════════════════════════════════
module "rds" {
  source = "./modules/rds"

  region = var.region
  tags   = local.tags

  db_instances = {
    "${var.db_instance}"= {
      engine            = "postgres"
      engine_version    = "14.15"
      instance_class    = "db.t3.micro"
      allocated_storage = 20

      username = var.db_username
      db_name  = var.db_name
      port     = 5432

      subnet_ids             = [
        module.eks_network.subnet_ids["private-db-1a"],
        module.eks_network.subnet_ids["private-db-1c"]
      ]
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
        "${var.eks_node_group_name}" = {
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


# This data source to get the auto-created EKS node SG
data "aws_security_group" "eks_node_auto_sg" {
  depends_on = [module.eks]  # Wait for EKS to create it

  filter {
    name   = "tag:aws:eks:cluster-name"
    values = [var.eks_cluster_name]
  }
  
  filter {
    name   = "tag:kubernetes.io/cluster/${var.eks_cluster_name}"
    values = ["owned"]
  }
}


# ═══════════════════════════════════════════════════════════════════════════════
# Security Group Rules
# ═══════════════════════════════════════════════════════════════════════════════

module "sg-rules" {
  source = "./modules/security-group-rule"
  depends_on = [data.aws_security_group.eks_node_auto_sg]

  rules = {
    # 1. Allow PostgreSQL from EKS nodes to RDS
    rds_from_eks = {
      type                     = "ingress"
      security_group_id        = module.sg.security_group_ids["rds-sg"]
      source_security_group_id = data.aws_security_group.eks_node_auto_sg.id

      from_port = 5432
      to_port   = 5432
      protocol  = "tcp"

      description = "PostgreSQL from EKS nodes only"
    }

    # 2. SSH access to EKS nodes
    eks_node_ssh = {
      type              = "ingress"
      security_group_id = data.aws_security_group.eks_node_auto_sg.id
      cidr_blocks       = ["0.0.0.0/0"]

      from_port = 22
      to_port   = 22
      protocol  = "tcp"

      description = "SSH from anywhere"
    }

    # 3. NodePort services for EKS nodes
    eks_node_nodeport = {
      type              = "ingress"
      security_group_id = data.aws_security_group.eks_node_auto_sg.id
      cidr_blocks       = ["10.0.0.0/16"]  # Your VPC CIDR

      from_port = 1025
      to_port   = 65535
      protocol  = "tcp"

      description = "NodePort services within VPC"
    }

    # 4. HTTPS access to EKS API
    eks_node_https = {
      type              = "ingress"
      security_group_id = data.aws_security_group.eks_node_auto_sg.id
      cidr_blocks       = ["0.0.0.0/0"]

      from_port = 443
      to_port   = 443
      protocol  = "tcp"

      description = "HTTPS to EKS API"
    }

    # 5. HTTP access to EKS API
    eks_node_http = {
      type              = "ingress"
      security_group_id = data.aws_security_group.eks_node_auto_sg.id
      cidr_blocks       = ["0.0.0.0/0"]

      from_port = 80
      to_port   = 80
      protocol  = "tcp"

      description = "HTTP to EKS API"
    }
  }
}








# ═══════════════════════════════════════════════════════════════════════════════
# IRSA Setup - MUST be after EKS cluster creation
# ═══════════════════════════════════════════════════════════════════════════════

# Wait for cluster to be fully created
resource "time_sleep" "wait_for_eks" {
  depends_on = [module.eks] # Wait for creation to START
  
  create_duration = "90s" # For OIDC to be available, Give it time to be READY
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
        "owner" = "devops-team"
      }
    }

    monitoring = {
      name = "monitoring"
      labels = {
        category = "platform"
        tool     = "monitoring"
      }
      annotations = {
        "owner" = "devops-team"
      }
    }

    # Application namespaces
    backend = {
      name = "backend"
      labels = {
        category = "application"
        framework     = "django fw"
      }
      annotations = {
        "owner" = "devops-team"
      }
    }

    frontend = {
      name = "frontend"
      labels = {
        category = "application"
        framework     = "react"
      }
      annotations = {
        "owner" = "devops-team"
      }
    }

    memcached = {
      name = "memcached"
      labels = {
        category = "data"
        service  = "cache"
      }
      annotations = {
        "owner" = "devops-team"
      }
    }

    cert-manager = {
      name = "cert-manager"
      labels = {
        category = "certificates"
        cert = "cert"
      }
      annotations = {
        "owner" = "devops-team"
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
      role_name       = "${var.project_name}-backend-irsa-role"
      policy_name     = "${var.project_name}-backend-secrets-policy"
      policy_document = {
        Version = "2012-10-17"
        Statement = [
          {
          Effect   = "Allow"
          Action   = [
              "secretsmanager:GetSecretValue", 
              "secretsmanager:DescribeSecret"
            ]
          Resource = "*"
          },
          {
            Effect   = "Allow"
            Action   = [
              "rds-db:connect",  # Allows RDS IAM Database Authentication
              "rds:DescribeDBInstances",
              "rds:DescribeDBClusters"
            ]
            Resource = "*"
          }
        ]
      }
      namespace   = "backend"
      k8s_sa_name = "backend-sa"
    }

    alb_controller = {
      role_name       = "${var.project_name}-alb-controller-irsa-role"
      policy_name     = "${var.project_name}-alb-controller-policy"
      policy_document = {
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "iam:CreateServiceLinkedRole",
              "ec2:DescribeAccountAttributes",
              "ec2:DescribeAddresses",
              "ec2:DescribeAvailabilityZones",
              "ec2:DescribeInternetGateways",
              "ec2:DescribeVpcs",
              "ec2:DescribeVpcPeeringConnections",
              "ec2:DescribeSubnets",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeInstances",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DescribeTags",
              "ec2:DescribeRouteTables",
              "ec2:GetCoipPoolUsage",
              "ec2:DescribeCoipPools",
              "elasticloadbalancing:DescribeLoadBalancers",
              "elasticloadbalancing:DescribeLoadBalancerAttributes",
              "elasticloadbalancing:DescribeListeners",
              "elasticloadbalancing:DescribeListenerCertificates",
              "elasticloadbalancing:DescribeSSLPolicies",
              "elasticloadbalancing:DescribeRules",
              "elasticloadbalancing:DescribeTargetGroups",
              "elasticloadbalancing:DescribeTargetGroupAttributes",
              "elasticloadbalancing:DescribeTargetHealth",
              "elasticloadbalancing:DescribeTags"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:RevokeSecurityGroupIngress",
              "ec2:CreateSecurityGroup",
              "ec2:DeleteSecurityGroup",
              "ec2:CreateTags",
              "ec2:DeleteTags",
              "ec2:ModifyInstanceAttribute",
              "ec2:ModifyNetworkInterfaceAttribute",
              "ec2:ModifySecurityGroupRules"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "elasticloadbalancing:AddListenerCertificates",
              "elasticloadbalancing:RemoveListenerCertificates",
              "elasticloadbalancing:ModifyListener",
              "elasticloadbalancing:ModifyLoadBalancerAttributes",
              "elasticloadbalancing:SetIpAddressType",
              "elasticloadbalancing:SetSecurityGroups",
              "elasticloadbalancing:SetSubnets",
              "elasticloadbalancing:DeleteLoadBalancer",
              "elasticloadbalancing:CreateLoadBalancer",
              "elasticloadbalancing:CreateListener",
              "elasticloadbalancing:DeleteListener",
              "elasticloadbalancing:CreateRule",
              "elasticloadbalancing:DeleteRule",
              "elasticloadbalancing:ModifyRule"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "elasticloadbalancing:RegisterTargets",
              "elasticloadbalancing:DeregisterTargets",
              "elasticloadbalancing:CreateTargetGroup",
              "elasticloadbalancing:DeleteTargetGroup",
              "elasticloadbalancing:ModifyTargetGroup",
              "elasticloadbalancing:ModifyTargetGroupAttributes",
              "acm:DescribeCertificate",
              "acm:ListCertificates",
              "elasticloadbalancing:*",
              "acm:DescribeCertificate",
              "acm:ListCertificates"
            ]
            Resource = "*"
          },
        ]
      }
      namespace   = "kube-system"
      k8s_sa_name = "aws-load-balancer-controller"
    }
    }
  
    tags = local.tags
}