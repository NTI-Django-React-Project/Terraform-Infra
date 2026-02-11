resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = each.key
  description             = each.value.description
  recovery_window_in_days = each.value.recovery_window_in_days
  kms_key_id              = each.value.kms_key_id

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.secret_string
}
