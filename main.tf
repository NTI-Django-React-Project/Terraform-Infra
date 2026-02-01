# ===========================
# VPC
# ===========================

module "vpc" {
  source = "./modules/vpc"

  region               = var.region
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ===========================
# Subnets
# ===========================

module "subnets" {
  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id

  subnets = {
    "public-1b" = {
      cidr_block        = "10.10.1.0/24"
      availability_zone = "eu-north-1b"
      tags              = { Type = "public", Tier = "web" }
    }
    "private-db-1a" = {
      cidr_block        = "10.10.2.0/24"
      availability_zone = "eu-north-1a"
      tags              = { Type = "private", Tier = "database" }
    }
    "private-k8s-1a" = {
      cidr_block        = "10.10.3.0/24"
      availability_zone = "eu-north-1a"
      tags              = { Type = "private", Tier = "k8s" }
    }
    "private-k8s-1b" = {
      cidr_block        = "10.10.4.0/24"
      availability_zone = "eu-north-1b"
      tags              = { Type = "private", Tier = "k8s" }
    }
    "private-k8s-1c" = {
      cidr_block        = "10.10.5.0/24"
      availability_zone = "eu-north-1c"
      tags              = { Type = "private", Tier = "k8s" }
    }
    "private-db-1b" = {
      cidr_block        = "10.10.6.0/24"
      availability_zone = "eu-north-1b"
      tags              = { Type = "private", Tier = "database" }
    }
  }
}

# ===========================
# Internet Gateway
# ===========================

module "internet_gateway" {
  source = "./modules/internet-gateway"

  region = var.region
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ===========================
# NAT Gateway
# ===========================

module "nat_gateway" {
  source = "./modules/nat-gateway"

  region = var.region
  vpc_id = module.vpc.vpc_id

  nat_gateways = {
    "nat-public" = {
      subnet_id = module.subnets.subnet_ids["public-1b"]
      tags      = { AZ = "eu-north-1b" }
    }
  }
}

# ===========================
# Route Tables
# ===========================

module "route_tables" {
  source = "./modules/route-table"

  region = var.region
  vpc_id = module.vpc.vpc_id

  route_tables = {
    "public" = {
      routes = [
        {
          cidr_block = "0.0.0.0/0"
          gateway_id = module.internet_gateway.internet_gateway_id
        }
      ]
      tags = { Type = "public" }
    }
    "private" = {
      routes = [
        {
          cidr_block     = "0.0.0.0/0"
          nat_gateway_id = module.nat_gateway.nat_gateway_ids["nat-public"]
        }
      ]
      tags = { Type = "private" }
    }
    "database" = {
      routes = []
      tags   = { Type = "private-isolated" }
    }
  }
}

# ===========================
# Route Table Associations
# ===========================

module "route_table_associations" {
  source = "./modules/route-table-association"

  region = var.region

  subnet_associations = {
    "public-1b-assoc" = {
      subnet_id      = module.subnets.subnet_ids["public-1b"]
      route_table_id = module.route_tables.route_table_ids["public"]
    }
    "private-k8s-1a-assoc" = {
      subnet_id      = module.subnets.subnet_ids["private-k8s-1a"]
      route_table_id = module.route_tables.route_table_ids["private"]
    }
    "private-k8s-1b-assoc" = {
      subnet_id      = module.subnets.subnet_ids["private-k8s-1b"]
      route_table_id = module.route_tables.route_table_ids["private"]
    }
    "private-k8s-1c-assoc" = {
      subnet_id      = module.subnets.subnet_ids["private-k8s-1c"]
      route_table_id = module.route_tables.route_table_ids["private"]
    }
    "private-db-1a-assoc" = {
      subnet_id      = module.subnets.subnet_ids["private-db-1a"]
      route_table_id = module.route_tables.route_table_ids["database"]
    }
    "private-db-1b-assoc" = {
      subnet_id      = module.subnets.subnet_ids["private-db-1b"]
      route_table_id = module.route_tables.route_table_ids["database"]
    }
  }
}

# ===========================
# Security Groups
# ===========================

module "security_groups" {
  source = "./modules/security-group"

  vpc_id = module.vpc.vpc_id

  security_groups = {
    "jenkins-sg" = {
      description = "Security group for Jenkins server"
      ingress_rules = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "SSH access"
        },
        {
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Jenkins web interface"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound"
        }
      ]
      tags = { Service = "jenkins" }
    }
    "k8s-sg" = {
      description = "Security group for K8s nodes"
      ingress_rules = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "SSH access"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound"
        }
      ]
      tags = { Service = "k8s" }
    }
    "rds-sg" = {
      description = "Security group for RDS database"
      ingress_rules = [
        {
          from_port   = 5432
          to_port     = 5432
          protocol    = "tcp"
          cidr_blocks = ["10.10.0.0/16"]
          description = "PostgreSQL access from VPC"
        }
      ]
      egress_rules = []
      tags = { Service = "rds" }
    }
  }
}

# Add Jenkins SG to K8s SG ingress rules (for inter-communication)
resource "aws_security_group_rule" "k8s_from_jenkins" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = module.security_groups.security_group_ids["jenkins-sg"]
  security_group_id        = module.security_groups.security_group_ids["k8s-sg"]
  description              = "Allow all traffic from Jenkins"
}

# ===========================
# EC2 Instances
# ===========================

# User data scripts
locals {
  jenkins_user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    
    # Install Jenkins
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install java-11-openjdk -y
    yum install jenkins -y
    systemctl start jenkins
    systemctl enable jenkins
    
    echo "Jenkins installed successfully"
  EOF

  k8s_user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    echo "K8s node configured successfully"
  EOF
}

module "ec2_instances" {
  source = "./modules/ec2"

  instances = {
    "jenkins-server" = {
      ami                         = var.ami_id
      instance_type               = "t3.micro"
      subnet_id                   = module.subnets.subnet_ids["public-1b"]
      security_group_ids          = [module.security_groups.security_group_ids["jenkins-sg"]]
      associate_public_ip_address = true
      user_data                   = local.jenkins_user_data
      root_volume_size            = 30
      tags                        = { Role = "jenkins", Tier = "web" }
    }
    "k8s-node-1a" = {
      ami                = var.ami_id
      instance_type      = "t3.micro"
      subnet_id          = module.subnets.subnet_ids["private-k8s-1a"]
      security_group_ids = [module.security_groups.security_group_ids["k8s-sg"]]
      user_data          = local.k8s_user_data
      root_volume_size   = 30
      tags               = { Role = "k8s-worker", AZ = "eu-north-1a" }
    }
    "k8s-node-1b" = {
      ami                = var.ami_id
      instance_type      = "t3.micro"
      subnet_id          = module.subnets.subnet_ids["private-k8s-1b"]
      security_group_ids = [module.security_groups.security_group_ids["k8s-sg"]]
      user_data          = local.k8s_user_data
      root_volume_size   = 30
      tags               = { Role = "k8s-worker", AZ = "eu-north-1b" }
    }
    "k8s-node-1c" = {
      ami                = var.ami_id
      instance_type      = "t3.micro"
      subnet_id          = module.subnets.subnet_ids["private-k8s-1c"]
      security_group_ids = [module.security_groups.security_group_ids["k8s-sg"]]
      user_data          = local.k8s_user_data
      root_volume_size   = 30
      tags               = { Role = "k8s-worker", AZ = "eu-north-1c" }
    }
  }
}

# ===========================
# RDS Database
# ===========================

module "rds" {
  source = "./modules/rds"

  region = var.region

  db_instances = {
    "app-database" = {
      engine            = "postgres"
      engine_version    = "15.3"
      instance_class    = "db.t3.micro"
      allocated_storage = 20
      username          = var.db_username
      password          = var.db_password
      db_name           = var.db_name
      port              = 5432

      subnet_ids = [
        module.subnets.subnet_ids["private-db-1a"],
        module.subnets.subnet_ids["private-db-1b"]
      ]

      vpc_security_group_ids = [module.security_groups.security_group_ids["rds-sg"]]

      # Multi-AZ for high availability
      multi_az = true

      # Backup configuration
      backup_retention_period = 7
      backup_window           = "03:00-04:00"
      maintenance_window      = "mon:04:00-mon:05:00"

      # For production, set skip_final_snapshot to false
      skip_final_snapshot     = true
      deletion_protection     = false
      delete_automated_backups = true

      # Storage
      storage_type      = "gp3"
      storage_encrypted = true

      tags = {
        Component = "database"
        Tier      = "data"
      }
    }
  }
}

# ===========================
# ECR
# ===========================

module "ecr" {
  source = "./modules/ecr"

  region = var.region

  repositories = {
    "app-frontend" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      force_delete         = true
      tags                 = { Component = "frontend" }
    }
    "app-backend" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      force_delete         = true
      tags                 = { Component = "backend" }
    }
    "app-worker" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      force_delete         = true
      tags                 = { Component = "worker" }
    }
  }
}
