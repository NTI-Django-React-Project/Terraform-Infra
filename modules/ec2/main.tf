
# Generate TLS private key for each instance
resource "tls_private_key" "this" {
  for_each = var.instances

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from generated private key
resource "aws_key_pair" "this" {
  for_each = var.instances

  key_name   = "${each.key}-key"
  public_key = tls_private_key.this[each.key].public_key_openssh

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${each.key}-key"
    }
  )
}

# Create IAM instance profiles for instances that specify iam_role_name
resource "aws_iam_instance_profile" "this" {
  for_each = {
    for k, v in var.instances : k => v
    if var.create_instance_profiles && try(v.iam_role_name, null) != null
  }

  name = "${each.key}-instance-profile"
  role = each.value.iam_role_name
  
  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = "${each.key}-instance-profile"
      Instance    = each.key
      ManagedBy   = "ec2-module"
    }
  )
}

# EC2 Instance
resource "aws_instance" "this" {
  for_each = var.instances

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = each.value.security_group_ids
  key_name                    = aws_key_pair.this[each.key].key_name
  associate_public_ip_address = lookup(each.value, "associate_public_ip_address", false)
  
  user_data                   = lookup(each.value, "user_data", null)
  user_data_replace_on_change = lookup(each.value, "user_data_replace_on_change", false)

  # Root block device
  root_block_device {
    volume_type           = lookup(each.value, "root_volume_type", "gp3")
    volume_size           = lookup(each.value, "root_volume_size", 20)
    delete_on_termination = lookup(each.value, "root_delete_on_termination", true)
    encrypted             = lookup(each.value, "root_encrypted", true)
  }

  # IAM instance profile
  iam_instance_profile = (
    var.create_instance_profiles && try(each.value.iam_role_name, null) != null
  ) ? aws_iam_instance_profile.this[each.key].name : lookup(each.value, "iam_instance_profile", null)

  # Monitoring
  monitoring = lookup(each.value, "enable_detailed_monitoring", false)

  # Metadata options
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )

  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [aws_key_pair.this]
}

# Store private keys locally (for convenience - in production use AWS Secrets Manager)
resource "local_file" "private_key" {
  for_each = var.instances

  content         = tls_private_key.this[each.key].private_key_pem
  filename        = "${path.module}/../../keys/${each.key}-private-key.pem"
  file_permission = "0400"
}
