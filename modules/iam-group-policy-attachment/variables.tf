variable "attachments" {
  description = "Map of group policy attachments to create"
  type = map(object({
    group      = string
    policy_arn = string
  }))
  validation {
    condition = alltrue([
      for k, v in var.attachments : length(v.group) >= 1 && length(v.group) <= 128
    ])
    error_message = "Group names must be between 1 and 128 characters."
  }
  validation {
    condition = alltrue([
      for k, v in var.attachments : can(regex("^[a-zA-Z0-9+=,.@_-]+$", v.group))
    ])
    error_message = "Group names can only contain alphanumeric characters and +=,.@_- symbols."
  }
  validation {
    condition = alltrue([
      for k, v in var.attachments : can(regex("^arn:aws:iam::[0-9]{12}:policy/.*$", v.policy_arn)) || can(regex("^arn:aws:iam::aws:policy/.*$", v.policy_arn))
    ])
    error_message = "Policy ARN must be a valid IAM policy ARN format."
  }
}
