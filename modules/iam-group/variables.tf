variable "groups" {
  description = "Map of IAM groups to create"
  type = map(object({
    path = optional(string, "/")
  }))
  validation {
    condition = alltrue([
      for k, v in var.groups : length(k) >= 1 && length(k) <= 128
    ])
    error_message = "Group names must be between 1 and 128 characters."
  }
  validation {
    condition = alltrue([
      for k, v in var.groups : can(regex("^[a-zA-Z0-9+=,.@_-]+$", k))
    ])
    error_message = "Group names can only contain alphanumeric characters and +=,.@_- symbols."
  }
  validation {
    condition = alltrue([
      for k, v in var.groups : can(regex("^/.*/$", "${v.path}/")) || v.path == "/"
    ])
    error_message = "Path must begin and end with / (e.g., /division/subdivision/)."
  }
}
