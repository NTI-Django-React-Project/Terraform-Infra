# ─── General ────────────────────────────────────────────────────────────────
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name (appears in tags and resource names)"
  type        = string
  default     = "stand-alone-jenkins"
}

# ─── Network ────────────────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnets" {
  description = "stand-alone Jenkins Subnet"
  type        = list(string)
  default = [
    "10.20.1.0/24",
  ]
}


# ─── EC2 / Jenkins ──────────────────────────────────────────────────────────
variable "ami_id" {
  description = "AMI ID for the Jenkins EC2 instance (Ubuntu, eu-north-1)"
  type        = string
  default     = "ami-073130f74f5ffb161"
}

