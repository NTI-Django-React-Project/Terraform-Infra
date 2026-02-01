
resource "aws_iam_policy" "this" {
  for_each = var.policies

  name        = each.key
  path        = each.value.path
  description = each.value.description
  policy      = each.value.policy_document

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

# Predefined full privilege policy
locals {
  full_privilege_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}
