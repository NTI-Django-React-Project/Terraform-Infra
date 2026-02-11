/**
 * IAM Role Policy Attachment Module
 * 
 * This module attaches one or more IAM policies to an IAM role.
 * Supports both AWS managed policies and customer managed policies.
 */

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.policy_arns)

  role       = var.role_name
  policy_arn = each.value
}
