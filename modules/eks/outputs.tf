# ───────────────────────────────
# EKS Clusters
# ───────────────────────────────

# Cluster ARNs
output "cluster_arns" {
  description = "All EKS cluster name → ARN pairs"
  value = { for name, cluster in var.clusters : name => cluster.cluster_role_arn } 
  # Using cluster_role_arn as placeholder for ARN until real resource is created; replace with actual aws_eks_cluster.arn if you use aws_eks_cluster resource
}

# Cluster endpoints
output "cluster_endpoints" {
  description = "All EKS cluster API endpoints"
  value = { for name, cluster in var.clusters : name => "https://${name}.eks.amazonaws.com" } 
  # Replace with actual aws_eks_cluster.endpoint
}

# Cluster CA (base64) – needed for kubeconfig
output "cluster_certificate_authorities" {
  description = "All EKS cluster certificate authorities (base64)"
  value = { for name, cluster in var.clusters : name => "" } 
  sensitive = true
  # Replace empty string with actual aws_eks_cluster.certificate_authority[0].data
}

# Node group ARNs
output "node_group_arns" {
  description = "All node group ARNs per cluster"
  value = { for cname, cluster in var.clusters : cname => { for ng, ngcfg in cluster.node_groups : ng => cluster.node_role_arn } }
}

# Node group statuses
output "node_group_statuses" {
  description = "All node group statuses (placeholder)"
  value = { for cname, cluster in var.clusters : cname => { for ng, ngcfg in cluster.node_groups : ng => "ACTIVE" } }
}

# Node group IAM roles
output "node_group_iam_role_arns" {
  description = "All node group IAM role ARNs per cluster"
  value = { for cname, cluster in var.clusters : cname => { for ng, ngcfg in cluster.node_groups : ng => cluster.node_role_arn } }
}

# Optional: expose node group subnet IDs per cluster
output "node_group_subnet_ids" {
  description = "Subnet IDs used by each EKS node group"
  value = {
    for cname, cluster in var.clusters : cname => {
      for ng_name, ng in cluster.node_groups :
      ng_name => ng.subnet_ids
    }
  }
}
