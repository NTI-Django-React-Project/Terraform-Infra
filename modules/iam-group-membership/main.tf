
resource "aws_iam_user_group_membership" "this" {
  for_each = var.memberships

  user   = each.value.user
  groups = each.value.groups
}
