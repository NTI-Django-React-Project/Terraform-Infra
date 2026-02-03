# ─── General ────────────────────────────────────────────────────────────────
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name (appears in tags and resource names)"
  type        = string
  default     = "eks-infrastructure"
}

variable "environment" {
  description = "Environment label (appears in tags)"
  type        = string
  default     = "production"
}

# ─── Network ────────────────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

# ─── EC2 / Jenkins ──────────────────────────────────────────────────────────
variable "jenkins_subnet" {
  description = "Jenkins Public Subnet IP"
  type        = string
  default     = "10.10.1.0/24"
}

variable "ami_id" {
  description = "AMI ID for the Jenkins EC2 instance (Amazon Linux 2, eu-north-1)"
  type        = string
  default     = "ami-0989fb15ce71ba39e"
}

# ─── RDS ────────────────────────────────────────────────────────────────────
variable "rds_subnets" {
  description = "RDS Subnets"
  type = list(string)
  default = [
    "10.10.2.0/24",
    "10.10.6.0/24",
    ]
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true

  validation {
  condition     = !contains(["admin","root","postgres"], lower(var.db_username))
  error_message = "The username is reserved by the database engine. Pick another."
  }
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the database to create inside RDS"
  type        = string
  default     = "appdb"
}

# ─── EKS ────────────────────────────────────────────────────────────────────
variable "eks_subnets" {
  description = "EKS Nodes Subnets"
  type        = list(string)
  default = [
    "10.10.3.0/24",
    "10.10.4.0/24",
    "10.10.5.0/24",
  ]
}

variable "eks_cluster_name" {
  description = "Default EKS cluster name"
  type        = string
  default     = "eks-cluster"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.eks_cluster_name))
    error_message = "Cluster name must start with a letter; only letters, digits and hyphens allowed."
  }
}

variable "eks_kubernetes_version" {
  description = "Default Kubernetes version"
  type        = string
  default     = "1.29"

  validation {
    condition     = contains(["1.27", "1.28", "1.29", "1.30", "1.31"], var.eks_kubernetes_version)
    error_message = "Supported versions: 1.27 – 1.31."
  }
}

variable "eks_node_instance_type" {
  description = "Default instance type for EKS worker nodes"
  type        = string
  default     = "t3.micro"
}

variable "eks_node_disk_size" {
  description = "Root EBS volume size (GB) on each EKS worker node"
  type        = number
  default     = 20
}

variable "eks_node_count" {
  description = "Default desired / min / max node count (all three set to this value)"
  type        = number
  default     = 3
}
