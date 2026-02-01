
resource "aws_iam_group_policy_attachment" "this" {
  for_each = var.attachments

  group      = each.value.group
  policy_arn = each.value.policy_arn
}
