# ───────────────────────────────
# EKS Clusters - ACTUAL RESOURCE OUTPUTS
# ───────────────────────────────

# Cluster names (the actual resource names)
output "cluster_names" {
  description = "Map of cluster key to actual cluster name"
  value       = { for k, v in aws_eks_cluster.this : k => v.name }
}

# Single cluster name (if you only have one cluster)
output "cluster_name" {
  description = "Name of the single EKS cluster (if only one)"
  value       = length(aws_eks_cluster.this) == 1 ? values(aws_eks_cluster.this)[0].name : null
}

# Single cluster ARN
output "cluster_arn" {
  description = "ARN of the single EKS cluster (if only one)"
  value       = length(aws_eks_cluster.this) == 1 ? values(aws_eks_cluster.this)[0].arn : null
}

# OIDC issuer URLs
output "cluster_oidc_issuers" {
  description = "OIDC issuer URLs for all clusters"
  value       = { for k, v in aws_eks_cluster.this : k => v.identity[0].oidc[0].issuer }
}

# Single OIDC issuer
output "cluster_oidc_issuer" {
  description = "OIDC issuer URL for the single cluster (if only one)"
  value       = length(aws_eks_cluster.this) == 1 ? values(aws_eks_cluster.this)[0].identity[0].oidc[0].issuer : null
}

# Cluster endpoints
output "cluster_endpoints" {
  description = "API endpoints for all clusters"
  value       = { for k, v in aws_eks_cluster.this : k => v.endpoint }
}

# Single cluster endpoint
output "cluster_endpoint" {
  description = "API endpoint for the single cluster (if only one)"
  value       = length(aws_eks_cluster.this) == 1 ? values(aws_eks_cluster.this)[0].endpoint : null
}

# Certificate authorities
output "cluster_certificate_authorities" {
  description = "Certificate authorities for all clusters"
  value       = { for k, v in aws_eks_cluster.this : k => v.certificate_authority[0].data }
  sensitive   = true
}

# Single certificate authority
output "cluster_certificate_authority" {
  description = "Certificate authority for the single cluster (if only one)"
  value       = length(aws_eks_cluster.this) == 1 ? values(aws_eks_cluster.this)[0].certificate_authority[0].data : null
  sensitive   = true
}

# Cluster ARNs (actual ARNs from AWS)
output "cluster_arns" {
  description = "All EKS cluster ARNs"
  value       = { for k, v in aws_eks_cluster.this : k => v.arn }
}

# ───────────────────────────────
# Node Group Outputs
# ───────────────────────────────

# Node group ARNs
output "node_group_arns" {
  description = "All node group ARNs per cluster"
  value = {
    for cluster_name in keys(aws_eks_cluster.this) : cluster_name => {
      for key, ng in aws_eks_node_group.this : 
      split("-", key)[1] => ng.arn
      if split("-", key)[0] == cluster_name
    }
  }
}

# Node group statuses
output "node_group_statuses" {
  description = "All node group statuses"
  value = {
    for cluster_name in keys(aws_eks_cluster.this) : cluster_name => {
      for key, ng in aws_eks_node_group.this : 
      split("-", key)[1] => ng.status
      if split("-", key)[0] == cluster_name
    }
  }
}

# Node group IAM roles (from your input)
output "node_group_iam_role_arns" {
  description = "All node group IAM role ARNs per cluster"
  value = { 
    for cname, cluster in var.clusters : cname => {
      for ng_name, ng in cluster.node_groups : ng_name => cluster.node_role_arn 
    }
  }
}

# Node group subnet IDs (from your input)
output "node_group_subnet_ids" {
  description = "Subnet IDs used by each EKS node group"
  value = {
    for cname, cluster in var.clusters : cname => {
      for ng_name, ng in cluster.node_groups : ng_name => ng.subnet_ids
    }
  }
}

# Optional: All node group resources
output "node_groups" {
  description = "All EKS node group resources"
  value       = aws_eks_node_group.this
}