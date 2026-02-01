output "cluster_ids" {
  description = "Map of cluster names to cluster IDs"
  value       = { for k, v in aws_eks_cluster.this : k => v.id }
}

output "cluster_arns" {
  description = "Map of cluster names to cluster ARNs"
  value       = { for k, v in aws_eks_cluster.this : k => v.arn }
}

output "cluster_endpoints" {
  description = "Map of cluster names to cluster endpoints"
  value       = { for k, v in aws_eks_cluster.this : k => v.endpoint }
}

output "cluster_certificate_authorities" {
  description = "Map of cluster names to certificate authority data"
  value       = { for k, v in aws_eks_cluster.this : k => v.certificate_authority[0].data }
  sensitive   = true
}

output "cluster_security_group_ids" {
  description = "Map of cluster names to cluster security group IDs"
  value       = { for k, v in aws_eks_cluster.this : k => v.vpc_config[0].cluster_security_group_id }
}

output "cluster_iam_role_arns" {
  description = "Map of cluster names to IAM role ARNs"
  value       = { for k, v in aws_iam_role.cluster : k => v.arn }
}

output "node_group_ids" {
  description = "Map of node group names to node group IDs"
  value       = { for k, v in aws_eks_node_group.this : k => v.id }
}

output "node_group_arns" {
  description = "Map of node group names to node group ARNs"
  value       = { for k, v in aws_eks_node_group.this : k => v.arn }
}

output "node_group_statuses" {
  description = "Map of node group names to statuses"
  value       = { for k, v in aws_eks_node_group.this : k => v.status }
}

output "node_group_iam_role_arns" {
  description = "Map of cluster names to node group IAM role ARNs"
  value       = { for k, v in aws_iam_role.node_group : k => v.arn }
}

output "clusters" {
  description = "Complete EKS cluster objects"
  value       = aws_eks_cluster.this
}

output "node_groups" {
  description = "Complete EKS node group objects"
  value       = aws_eks_node_group.this
}

output "kubeconfig" {
  description = "Kubeconfig data for each cluster"
  value = {
    for k, v in aws_eks_cluster.this : k => {
      apiVersion = "v1"
      kind       = "Config"
      clusters = [{
        cluster = {
          server                     = v.endpoint
          certificate-authority-data = v.certificate_authority[0].data
        }
        name = v.name
      }]
      contexts = [{
        context = {
          cluster = v.name
          user    = v.name
        }
        name = v.name
      }]
      current-context = v.name
      users = [{
        name = v.name
        user = {
          exec = {
            apiVersion = "client.authentication.k8s.io/v1beta1"
            command    = "aws"
            args = [
              "eks",
              "get-token",
              "--cluster-name",
              v.name
            ]
          }
        }
      }]
    }
  }
  sensitive = true
}
