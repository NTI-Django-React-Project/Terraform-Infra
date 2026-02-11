variable "instances" {
  description = "Map of EC2 instances to create"
  type = map(object({
    ami                         = string
    instance_type               = string
    subnet_id                   = string
    security_group_ids          = list(string)
    user_data                   = optional(string)
    user_data_replace_on_change = optional(bool, false)
    associate_public_ip_address = optional(bool, false)
    root_volume_type            = optional(string, "gp3")
    root_volume_size            = optional(number, 20)
    root_delete_on_termination  = optional(bool, true)
    root_encrypted              = optional(bool, true)
    iam_instance_profile        = optional(string)
    enable_detailed_monitoring  = optional(bool, false)
    iam_role_name               = optional(string)
    tags                        = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.instances : contains([
        "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge",
        "t2.micro", "t2.small", "t2.medium", "t2.large", "t2.xlarge", "t2.2xlarge",
        "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge", "m5.8xlarge",
        "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge", "c5.9xlarge", "m7i-flex.large"
      ], v.instance_type)
    ])
    error_message = "Instance type must be a valid EC2 instance type."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : can(regex("^subnet-[a-z0-9]+$", v.subnet_id))
    ])
    error_message = "All subnet IDs must be valid AWS subnet ID format (e.g., subnet-12345678)."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : can(regex("^ami-[a-z0-9]+$", v.ami))
    ])
    error_message = "All AMI IDs must be valid AWS AMI ID format (e.g., ami-12345678)."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : alltrue([
        for sg in v.security_group_ids : can(regex("^sg-[a-z0-9]+$", sg))
      ])
    ])
    error_message = "All security group IDs must be valid AWS security group ID format (e.g., sg-12345678)."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : v.root_volume_size >= 8 && v.root_volume_size <= 16384
    ])
    error_message = "Root volume size must be between 8 and 16384 GB."
  }
}

variable "tags" {
  description = "Common tags to apply to all EC2 instances"
  type        = map(string)
  default     = {}
}

variable "create_instance_profiles" {
  description = "Whether to create IAM instance profiles for instances that specify iam_role_name"
  type        = bool
  default     = true  # Default to creating them
}