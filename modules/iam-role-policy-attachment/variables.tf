variable "role_name" {
  description = "The name of the IAM role to which the policies should be attached."
  type        = string
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the role. Can include both AWS managed and customer managed policies."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.policy_arns) > 0
    error_message = "At least one policy ARN must be specified."
  }
}
