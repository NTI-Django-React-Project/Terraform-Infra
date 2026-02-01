variable "users" {
  description = "Map of IAM users to create"
  type = map(object({
    path              = optional(string, "/")
    force_destroy     = optional(bool, true)
    create_access_key = optional(bool, false)
    tags              = optional(map(string), {})
  }))
  validation {
    condition = alltrue([
      for k, v in var.users : length(k) >= 1 && length(k) <= 64
    ])
    error_message = "User names must be between 1 and 64 characters."
  }
  validation {
    condition = alltrue([
      for k, v in var.users : can(regex("^[a-zA-Z0-9+=,.@_-]+$", k))
    ])
    error_message = "User names can only contain alphanumeric characters and +=,.@_- symbols."
  }
  validation {
    condition = alltrue([
      for k, v in var.users : can(regex("^/.*/$", "${v.path}/")) || v.path == "/"
    ])
    error_message = "Path must begin and end with / (e.g., /division/subdivision/)."
  }
}

variable "tags" {
  description = "Common tags to apply to all IAM users"
  type        = map(string)
  default     = {}
}
