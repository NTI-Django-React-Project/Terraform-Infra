
resource "aws_iam_user" "this" {
  for_each = var.users

  name          = each.key
  path          = each.value.path
  force_destroy = each.value.force_destroy

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

resource "aws_iam_access_key" "this" {
  for_each = {
    for k, v in var.users : k => v
    if lookup(v, "create_access_key", false)
  }

  user = aws_iam_user.this[each.key].name
}
