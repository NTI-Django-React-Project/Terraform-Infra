variable "clusters" {
  description = "Map of EKS clusters to create"
  type = map(object({
    subnet_ids                = list(string)
    kubernetes_version        = optional(string, "1.28")
    endpoint_private_access   = optional(bool, true)
    endpoint_public_access    = optional(bool, true)
    public_access_cidrs       = optional(list(string), ["0.0.0.0/0"])
    security_group_ids        = optional(list(string), [])
    enabled_cluster_log_types = optional(list(string), ["api", "audit", "authenticator", "controllerManager", "scheduler"])
    kms_key_arn               = optional(string)
    node_groups = optional(map(object({
      subnet_ids     = list(string)
      desired_size   = number
      max_size       = number
      min_size       = number
      instance_types = list(string)
      capacity_type  = optional(string, "ON_DEMAND")
      disk_size      = optional(number, 20)
      max_unavailable = optional(number, 1)
      labels         = optional(map(string), {})
      tags           = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.clusters : length(k) >= 1 && length(k) <= 100
    ])
    error_message = "Cluster names must be between 1 and 100 characters."
  }

  validation {
    condition = alltrue([
      for k, v in var.clusters : can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", k))
    ])
    error_message = "Cluster names must start with a letter and contain only alphanumeric characters and hyphens."
  }

  validation {
    condition = alltrue([
      for k, v in var.clusters : length(v.subnet_ids) >= 2
    ])
    error_message = "At least 2 subnets are required for EKS cluster."
  }

  validation {
    condition = alltrue([
      for k, v in var.clusters : alltrue([
        for subnet_id in v.subnet_ids : can(regex("^subnet-[a-z0-9]+$", subnet_id))
      ])
    ])
    error_message = "All subnet IDs must be valid AWS subnet ID format (e.g., subnet-12345678)."
  }

  validation {
    condition = alltrue([
      for k, v in var.clusters : contains(
        ["1.24", "1.25", "1.26", "1.27", "1.28", "1.29", "1.30"],
        v.kubernetes_version
      )
    ])
    error_message = "Kubernetes version must be a supported EKS version (1.24-1.30)."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.clusters : [
        for ng_name, ng_config in lookup(v, "node_groups", {}) : 
          ng_config.min_size <= ng_config.desired_size && 
          ng_config.desired_size <= ng_config.max_size
      ]
    ]))
    error_message = "Node group sizes must satisfy: min_size <= desired_size <= max_size."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.clusters : [
        for ng_name, ng_config in lookup(v, "node_groups", {}) : 
          contains(["ON_DEMAND", "SPOT"], ng_config.capacity_type)
      ]
    ]))
    error_message = "Node group capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "tags" {
  description = "Common tags to apply to all EKS resources"
  type        = map(string)
  default     = {}
}
