/**
 * IAM Role Module
 * 
 * This module creates an AWS IAM role with customizable trust policy
 * and optional inline policies.
 */

resource "aws_iam_role" "this" {
  name                  = var.name
  name_prefix           = var.name_prefix
  description           = var.description
  path                  = var.path
  max_session_duration  = var.max_session_duration
  permissions_boundary  = var.permissions_boundary
  assume_role_policy    = var.assume_role_policy
  force_detach_policies = var.force_detach_policies

  dynamic "inline_policy" {
    for_each = var.inline_policies
    content {
      name   = inline_policy.value.name
      policy = inline_policy.value.policy
    }
  }

  tags = var.tags
}
