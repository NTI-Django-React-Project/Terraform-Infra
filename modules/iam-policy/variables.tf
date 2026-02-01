variable "policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    path            = optional(string, "/")
    description     = optional(string, "")
    policy_document = string
    tags            = optional(map(string), {})
  }))
  validation {
    condition = alltrue([
      for k, v in var.policies : length(k) >= 1 && length(k) <= 128
    ])
    error_message = "Policy names must be between 1 and 128 characters."
  }
  validation {
    condition = alltrue([
      for k, v in var.policies : can(regex("^[a-zA-Z0-9+=,.@_-]+$", k))
    ])
    error_message = "Policy names can only contain alphanumeric characters and +=,.@_- symbols."
  }
  validation {
    condition = alltrue([
      for k, v in var.policies : can(regex("^/.*/$", "${v.path}/")) || v.path == "/"
    ])
    error_message = "Path must begin and end with / (e.g., /division/subdivision/)."
  }
  validation {
    condition = alltrue([
      for k, v in var.policies : can(jsondecode(v.policy_document))
    ])
    error_message = "Policy document must be valid JSON."
  }
}

variable "tags" {
  description = "Common tags to apply to all IAM policies"
  type        = map(string)
  default     = {}
}

# Helper variable for creating full privilege policy
variable "create_full_privilege_policy" {
  description = "Whether to create a full privilege policy"
  type        = bool
  default     = false
}

variable "full_privilege_policy_name" {
  description = "Name for the full privilege policy if created"
  type        = string
  default     = "FullPrivilegePolicy"
  validation {
    condition     = length(var.full_privilege_policy_name) >= 1 && length(var.full_privilege_policy_name) <= 128
    error_message = "Policy name must be between 1 and 128 characters."
  }
}
