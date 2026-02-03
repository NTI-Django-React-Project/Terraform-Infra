variable "clusters" {
  description = <<EOT
Map of EKS clusters to create.  
Each key is the cluster name. Each value should contain:
- subnet_ids: list of private subnet IDs
- kubernetes_version: version string (e.g., "1.28")
- cluster_role_arn: ARN of the pre-created IAM role for the cluster
- node_role_arn: ARN of the pre-created IAM role for the node group
- node_groups: map of node group configurations
- tags: map of tags
EOT

  type = map(object({
    subnet_ids         = list(string)
    kubernetes_version = string
    cluster_role_arn   = string
    node_role_arn      = string
    node_groups        = map(object({
      subnet_ids     = list(string)
      desired_size   = number
      min_size       = number
      max_size       = number
      instance_types = list(string)
      disk_size      = number
      capacity_type  = optional(string, "ON_DEMAND")
      labels         = optional(map(string), {})
      tags           = optional(map(string), {})
      max_unavailable = optional(number, 1)
    }))
    tags = map(string)
  }))
}

variable "tags" {
  description = "Default tags applied to all EKS resources"
  type        = map(string)
  default     = {}
}
