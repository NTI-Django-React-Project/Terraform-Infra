variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_oidc_issuer" {
  description = "EKS cluster OIDC issuer URL (e.g., https://oidc.eks.region.amazonaws.com/id/CLUSTER_ID)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "create_oidc_provider" {
  description = "Whether to create OIDC provider (set to false if already exists)"
  type        = bool
  default     = true
}

variable "service_accounts" {
  description = "Map of service account configurations"
  type = map(object({
    role_name       = string
    policy_name     = string
    policy_document = any
    namespace       = string
    k8s_sa_name     = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

