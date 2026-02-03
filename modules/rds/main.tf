
resource "aws_db_subnet_group" "this" {
  for_each = var.db_instances

  name       = "${each.key}-subnet-group"
  subnet_ids = each.value.subnet_ids

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${each.key}-subnet-group"
    }
  )
}

resource "aws_db_instance" "this" {
  for_each = var.db_instances

  # Basic settings
  identifier     = each.key
  engine         = each.value.engine
  engine_version = each.value.engine_version
  instance_class = each.value.instance_class

  # Storage
  allocated_storage     = each.value.allocated_storage
  max_allocated_storage = lookup(each.value, "max_allocated_storage", null)
  storage_type          = lookup(each.value, "storage_type", "gp3")
  storage_encrypted     = lookup(each.value, "storage_encrypted", true)
  kms_key_id            = lookup(each.value, "kms_key_id", null)
  iops                  = lookup(each.value, "iops", null)
  storage_throughput    = lookup(each.value, "storage_throughput", null)

  # Database settings
  db_name  = lookup(each.value, "db_name", null)
  username = each.value.username
  password = each.value.password
  port     = lookup(each.value, "port", null)

  # Network settings
  db_subnet_group_name   = aws_db_subnet_group.this[each.key].name
  vpc_security_group_ids = lookup(each.value, "vpc_security_group_ids", [])
  publicly_accessible    = lookup(each.value, "publicly_accessible", false)

  # Backup settings
  backup_retention_period = lookup(each.value, "backup_retention_period", 7)
  backup_window           = lookup(each.value, "backup_window", null)
  maintenance_window      = lookup(each.value, "maintenance_window", null)
  skip_final_snapshot     = lookup(each.value, "skip_final_snapshot", true)
  final_snapshot_identifier = lookup(each.value, "skip_final_snapshot", true) ? null : "${each.key}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot  = lookup(each.value, "copy_tags_to_snapshot", true)

  # Performance and monitoring
  performance_insights_enabled          = false
  #performance_insights_retention_period = lookup(each.value, "performance_insights_retention_period", 7)
  #performance_insights_kms_key_id       = lookup(each.value, "performance_insights_kms_key_id", null)
  enabled_cloudwatch_logs_exports       = lookup(each.value, "enabled_cloudwatch_logs_exports", [])
  monitoring_interval                   = lookup(each.value, "monitoring_interval", 0)
  monitoring_role_arn                   = lookup(each.value, "monitoring_role_arn", null)

  # High availability
  multi_az               = lookup(each.value, "multi_az", false)
  availability_zone      = lookup(each.value, "availability_zone", null)

  # Additional settings
  auto_minor_version_upgrade = lookup(each.value, "auto_minor_version_upgrade", true)
  apply_immediately          = lookup(each.value, "apply_immediately", false)
  deletion_protection        = lookup(each.value, "deletion_protection", false)
  delete_automated_backups   = lookup(each.value, "delete_automated_backups", true)

  # Parameter and option groups
  parameter_group_name = lookup(each.value, "parameter_group_name", null)
  option_group_name    = lookup(each.value, "option_group_name", null)

  # Character set
  character_set_name = lookup(each.value, "character_set_name", null)

  # Timezone
  timezone = lookup(each.value, "timezone", null)

  # IAM authentication
  iam_database_authentication_enabled = lookup(each.value, "iam_database_authentication_enabled", false)

  # Replicas
  replicate_source_db = lookup(each.value, "replicate_source_db", null)

  # Snapshot
  snapshot_identifier = lookup(each.value, "snapshot_identifier", null)

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )

  depends_on = [aws_db_subnet_group.this]
}
