variable "name" {
  description = "The name of the IAM role. Conflicts with name_prefix."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Creates a unique name beginning with the specified prefix. Conflicts with name."
  type        = string
  default     = null
}

variable "description" {
  description = "The description of the IAM role."
  type        = string
  default     = null
}

variable "path" {
  description = "The path to the role."
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "The maximum session duration (in seconds) for the role. Valid values are between 3600 and 43200."
  type        = number
  default     = 3600
}

variable "permissions_boundary" {
  description = "The ARN of the policy that is used to set the permissions boundary for the role."
  type        = string
  default     = null
}

variable "assume_role_policy" {
  description = "The policy document that grants an entity permission to assume the role (JSON format)."
  type        = string
}

variable "force_detach_policies" {
  description = "Whether to force detaching any policies the role has before destroying it."
  type        = bool
  default     = false
}

variable "inline_policies" {
  description = "List of inline policies to attach to the role."
  type = list(object({
    name   = string
    policy = string
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to assign to the IAM role."
  type        = map(string)
  default     = {}
}
