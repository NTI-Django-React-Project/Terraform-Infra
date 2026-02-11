variable "region" {
  description = "AWS region where ECR repositories will be created"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "repositories" {
  description = "Map of ECR repositories to create"
  type = map(object({
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)
    force_delete         = optional(bool, true)
    encryption_type      = optional(string, "AES256")
    kms_key              = optional(string, null)
    lifecycle_policy     = optional(string, null)
    tags                 = optional(map(string), {})
  }))
  validation {
    condition = alltrue([
      for k, v in var.repositories : contains(["MUTABLE", "IMMUTABLE"], v.image_tag_mutability)
    ])
    error_message = "Image tag mutability must be either 'MUTABLE' or 'IMMUTABLE'."
  }
  validation {
    condition = alltrue([
      for k, v in var.repositories : contains(["AES256", "KMS"], v.encryption_type)
    ])
    error_message = "Encryption type must be either 'AES256' or 'KMS'."
  }
  validation {
    condition = alltrue([
      for k, v in var.repositories : length(k) >= 2 && length(k) <= 256
    ])
    error_message = "Repository names must be between 2 and 256 characters."
  }
  validation {
    condition = alltrue([
      for k, v in var.repositories : can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*(/[a-z0-9]+(?:[._-][a-z0-9]+)*)*$", k))
    ])
    error_message = "Repository names must follow AWS ECR naming conventions (lowercase, alphanumeric, hyphens, underscores, forward slashes)."
  }
}

variable "tags" {
  description = "Common tags to apply to all ECR repositories"
  type        = map(string)
  default     = {}
}
