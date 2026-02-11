variable "secrets" {
  description = "Map of secrets to create in Secrets Manager"
  type = map(object({
    description             = optional(string, "")
    secret_string           = string
    recovery_window_in_days = optional(number, 7)
    kms_key_id              = optional(string, null)
    tags                    = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.secrets : length(k) >= 1 && length(k) <= 512
    ])
    error_message = "Secret names must be between 1 and 512 characters."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : can(regex("^[a-zA-Z0-9/_+=.@-]+$", k))
    ])
    error_message = "Secret names can only contain alphanumeric characters and /_+=.@- symbols."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : v.recovery_window_in_days >= 0 && v.recovery_window_in_days <= 30
    ])
    error_message = "Recovery window must be between 0 and 30 days. Use 0 to disable recovery and force immediate deletion."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : length(v.secret_string) >= 1
    ])
    error_message = "Secret string must not be empty."
  }
}

variable "tags" {
  description = "Common tags to apply to all secrets"
  type        = map(string)
  default     = {}
}
