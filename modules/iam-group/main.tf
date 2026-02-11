
resource "aws_iam_group" "this" {
  for_each = var.groups

  name = each.key
  path = each.value.path
}
