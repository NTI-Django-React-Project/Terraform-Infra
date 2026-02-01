variable "memberships" {
  description = "Map of user group memberships to create"
  type = map(object({
    user   = string
    groups = list(string)
  }))
  validation {
    condition = alltrue([
      for k, v in var.memberships : length(v.user) >= 1 && length(v.user) <= 64
    ])
    error_message = "User names must be between 1 and 64 characters."
  }
  validation {
    condition = alltrue([
      for k, v in var.memberships : can(regex("^[a-zA-Z0-9+=,.@_-]+$", v.user))
    ])
    error_message = "User names can only contain alphanumeric characters and +=,.@_- symbols."
  }
  validation {
    condition = alltrue([
      for k, v in var.memberships : length(v.groups) > 0
    ])
    error_message = "Each membership must have at least one group."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.memberships : [
        for g in v.groups : length(g) >= 1 && length(g) <= 128
      ]
    ]))
    error_message = "Group names must be between 1 and 128 characters."
  }
}
