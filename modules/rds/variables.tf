variable "region" {
  description = "AWS region where RDS instances will be created"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "db_instances" {
  description = "Map of RDS database instances to create"
  type = map(object({
    # Required parameters
    engine            = string
    engine_version    = string
    instance_class    = string
    allocated_storage = number
    username          = string
    subnet_ids        = list(string)

    # Optional parameters
    db_name                               = optional(string)
    port                                  = optional(number)
    storage_type                          = optional(string, "gp3")
    storage_encrypted                     = optional(bool, true)
    iops                                  = optional(number)
    storage_throughput                    = optional(number)
    max_allocated_storage                 = optional(number)
    vpc_security_group_ids                = optional(list(string), [])
    publicly_accessible                   = optional(bool, false)
    backup_retention_period               = optional(number, 7)
    backup_window                         = optional(string)
    maintenance_window                    = optional(string)
    skip_final_snapshot                   = optional(bool, true)
    copy_tags_to_snapshot                 = optional(bool, true)
    performance_insights_enabled          = optional(bool, false)
    performance_insights_retention_period = optional(number, 7)
    performance_insights_kms_key_id       = optional(string)
    enabled_cloudwatch_logs_exports       = optional(list(string), [])
    monitoring_interval                   = optional(number, 0)
    monitoring_role_arn                   = optional(string)
    multi_az                              = optional(bool, false)
    availability_zone                     = optional(string)
    auto_minor_version_upgrade            = optional(bool, true)
    apply_immediately                     = optional(bool, false)
    deletion_protection                   = optional(bool, false)
    delete_automated_backups              = optional(bool, true)
    parameter_group_name                  = optional(string)
    option_group_name                     = optional(string)
    character_set_name                    = optional(string)
    timezone                              = optional(string)
    iam_database_authentication_enabled   = optional(bool, false)
    replicate_source_db                   = optional(string)
    snapshot_identifier                   = optional(string)
    tags                                  = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.db_instances : contains([
        "mysql", "postgres", "mariadb", "oracle-ee", "oracle-ee-cdb", "oracle-se2",
        "oracle-se2-cdb", "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web"
      ], v.engine)
    ])
    error_message = "Engine must be a valid RDS engine type."
  }

  validation {
    condition = alltrue([
      for k, v in var.db_instances : v.allocated_storage >= 20
    ])
    error_message = "Allocated storage must be at least 20 GB."
  }

  validation {
    condition = alltrue([
      for k, v in var.db_instances : contains(["gp2", "gp3", "io1", "io2"], v.storage_type)
    ])
    error_message = "Storage type must be one of: gp2, gp3, io1, io2."
  }

  validation {
    condition = alltrue([
      for k, v in var.db_instances : length(v.subnet_ids) >= 2
    ])
    error_message = "At least 2 subnets are required for DB subnet group."
  }

  validation {
    condition = alltrue([
      for k, v in var.db_instances : v.backup_retention_period >= 0 && v.backup_retention_period <= 35
    ])
    error_message = "Backup retention period must be between 0 and 35 days."
  }

  validation {
    condition = alltrue([
      for k, v in var.db_instances : length(k) >= 1 && length(k) <= 63
    ])
    error_message = "DB instance identifiers must be between 1 and 63 characters."
  }

  validation {
    condition = alltrue([
      for k, v in var.db_instances : can(regex("^[a-z][a-z0-9-]*$", k))
    ])
    error_message = "DB instance identifiers must start with a letter and contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "tags" {
  description = "Common tags to apply to all RDS resources"
  type        = map(string)
  default     = {}
}
