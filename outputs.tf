# ===========================
# VPC Outputs
# ===========================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

# ===========================
# Subnet Outputs
# ===========================

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.subnets.subnet_ids
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.subnets.subnet_ids["public-1b"]
}

output "private_k8s_subnet_ids" {
  description = "Private K8s subnet IDs"
  value = [
    module.subnets.subnet_ids["private-k8s-1a"],
    module.subnets.subnet_ids["private-k8s-1b"],
    module.subnets.subnet_ids["private-k8s-1c"]
  ]
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs"
  value = [
    module.subnets.subnet_ids["private-db-1a"],
    module.subnets.subnet_ids["private-db-1b"]
  ]
}

# ===========================
# Gateway Outputs
# ===========================

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.internet_gateway.internet_gateway_id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.nat_gateway.nat_gateway_ids["nat-public"]
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP"
  value       = module.nat_gateway.nat_gateway_public_ips["nat-public"]
}

# ===========================
# Security Group Outputs
# ===========================

output "security_group_ids" {
  description = "Map of security group names to IDs"
  value       = module.security_groups.security_group_ids
}

output "jenkins_sg_id" {
  description = "Jenkins security group ID"
  value       = module.security_groups.security_group_ids["jenkins-sg"]
}

output "k8s_sg_id" {
  description = "K8s security group ID"
  value       = module.security_groups.security_group_ids["k8s-sg"]
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = module.security_groups.security_group_ids["rds-sg"]
}

# ===========================
# EC2 Outputs
# ===========================

output "ec2_instance_ids" {
  description = "Map of EC2 instance names to IDs"
  value       = module.ec2_instances.instance_ids
}

output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = module.ec2_instances.instance_public_ips["jenkins-server"]
}

output "jenkins_public_dns" {
  description = "Jenkins server public DNS"
  value       = module.ec2_instances.instance_public_dns["jenkins-server"]
}

output "k8s_node_private_ips" {
  description = "K8s node private IPs"
  value = {
    "k8s-node-1a" = module.ec2_instances.instance_private_ips["k8s-node-1a"]
    "k8s-node-1b" = module.ec2_instances.instance_private_ips["k8s-node-1b"]
    "k8s-node-1c" = module.ec2_instances.instance_private_ips["k8s-node-1c"]
  }
}

output "ssh_key_locations" {
  description = "Locations of SSH private keys for EC2 instances"
  value = {
    for name, key in module.ec2_instances.key_pair_names :
    name => "./keys/${name}-private-key.pem"
  }
}

# ===========================
# RDS Outputs
# ===========================

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_instance_endpoints["app-database"]
  sensitive   = true
}

output "rds_address" {
  description = "RDS database address"
  value       = module.rds.db_instance_addresses["app-database"]
}

output "rds_port" {
  description = "RDS database port"
  value       = module.rds.db_instance_ports["app-database"]
}

output "rds_database_name" {
  description = "RDS database name"
  value       = var.db_name
}

# ===========================
# ECR Outputs
# ===========================

output "ecr_repository_urls" {
  description = "Map of ECR repository names to URLs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "Map of ECR repository names to ARNs"
  value       = module.ecr.repository_arns
}

# ===========================
# Connection Information
# ===========================

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${module.ec2_instances.instance_public_ips["jenkins-server"]}:8080"
}

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = {
    jenkins = "ssh -i ./keys/jenkins-server-private-key.pem ec2-user@${module.ec2_instances.instance_public_ips["jenkins-server"]}"
  }
}

output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    region                 = var.region
    vpc_id                 = module.vpc.vpc_id
    vpc_cidr               = var.vpc_cidr
    availability_zones     = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
    total_subnets          = 6
    public_subnets         = 1
    private_subnets        = 5
    nat_gateways           = 1
    ec2_instances          = 4
    rds_instances          = 1
    ecr_repositories       = 3
    security_groups        = 3
    jenkins_public_ip      = module.ec2_instances.instance_public_ips["jenkins-server"]
    nat_gateway_public_ip  = module.nat_gateway.nat_gateway_public_ips["nat-public"]
  }
}
