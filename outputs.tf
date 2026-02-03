# ───────────────────────────────
# VPC
# ───────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = module.vpc.vpc_cidr_block
}

# ───────────────────────────────
# Subnets
# ───────────────────────────────
output "subnet_ids" {
  description = "All subnet name → ID pairs"
  value       = module.subnets.subnet_ids
}

# ───────────────────────────────
# Gateways
# ───────────────────────────────
output "igw_id" {
  description = "Internet Gateway ID"
  value       = module.igw.internet_gateway_id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.nat.nat_gateway_ids["nat-1b"]
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public (Elastic) IP"
  value       = module.nat.nat_gateway_public_ips["nat-1b"]
}

# ───────────────────────────────
# Security Groups
# ───────────────────────────────
output "security_group_ids" {
  description = "All SG name → ID pairs"
  value       = module.sg.security_group_ids
}

# ───────────────────────────────
# Jenkins
# ───────────────────────────────
output "jenkins_public_ip" {
  description = "Jenkins public IP"
  value       = module.ec2.instance_public_ips["jenkins-server"]
}

output "jenkins_url" {
  description = "Jenkins web UI"
  value       = "http://${module.ec2.instance_public_ips["jenkins-server"]}:8080"
}

output "jenkins_ssh_command" {
  description = "Ready-to-paste SSH command for Jenkins"
  value       = "ssh -i ./keys/jenkins-server-private-key.pem ec2-user@${module.ec2.instance_public_ips["jenkins-server"]}"
}

# ───────────────────────────────
# EKS
# ───────────────────────────────
# Use the known ARNs and roles you already created above
output "eks_cluster_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  value       = module.eks_cluster_role.arn
}

output "eks_node_role_arn" {
  description = "IAM role ARN for the EKS node group"
  value       = module.eks_node_role.arn
}

# Optional: expose node group subnet IDs
output "eks_node_subnet_ids" {
  description = "Subnet IDs used by EKS nodes"
  value       = module.eks.node_group_subnet_ids[var.eks_cluster_name]["default"]
}

# ───────────────────────────────
# RDS
# ───────────────────────────────
output "rds_endpoint" {
  description = "RDS endpoint (host:port)"
  value       = module.rds.db_instance_endpoints["app-db"]
  sensitive   = true
}

output "rds_address" {
  description = "RDS hostname"
  value       = module.rds.db_instance_addresses["app-db"]
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.db_instance_ports["app-db"]
}

output "rds_availability_zone" {
  description = "RDS availability zone"
  value       = "eu-north-1a"
}

# ───────────────────────────────
# ECR
# ───────────────────────────────
output "ecr_repository_urls" {
  description = "All ECR repository name → URL pairs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "All ECR repository name → ARN pairs"
  value       = module.ecr.repository_arns
}

# ───────────────────────────────
# Secrets Manager
# ───────────────────────────────
output "secret_arns" {
  description = "All secret name → ARN pairs"
  value       = module.secrets.secret_arns
}

output "db_secret_arn" {
  description = "ARN of the DB-credentials secret (use with aws secretsmanager get-secret-value)"
  value       = module.secrets.secret_arns["${var.project_name}/db/credentials"]
}

# ───────────────────────────────
# IAM Users & Groups
# ───────────────────────────────
output "iam_group_name" {
  description = "DevOps Engineers group name"
  value       = module.iam_group.group_names["DevOps-Engineers"]
}

output "iam_group_arn" {
  description = "DevOps Engineers group ARN"
  value       = module.iam_group.group_arns["DevOps-Engineers"]
}

output "iam_user_names" {
  description = "All IAM user names"
  value       = module.iam_users.user_names
}

output "iam_user_arns" {
  description = "All IAM user ARNs"
  value       = module.iam_users.user_arns
}

output "admin_policy_arn" {
  description = "Admin policy ARN attached to DevOps Engineers group"
  value       = module.iam_policy_admin.policy_arns["AdminAccess"]
}
