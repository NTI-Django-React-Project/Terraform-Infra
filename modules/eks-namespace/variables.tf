variable "namespaces" {
  description = "Map of namespace configurations"
  type = map(object({
    name   = string
    labels = optional(map(string), {})
    annotations = optional(map(string), {})
  }))
  default = {}
}

variable "create_default_labels" {
  description = "Whether to add default managed-by labels"
  type        = bool
  default     = true
}

variable "default_labels" {
  description = "Default labels to add to all namespaces"
  type        = map(string)
  default = {
    managed-by   = "terraform"
    provisioner  = "eks-module"
  }
}

variable "wait_for_cluster" {
  description = "Whether to wait for cluster to be ready"
  type        = bool
  default     = true
}