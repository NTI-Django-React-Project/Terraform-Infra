output "instance_ids" {
  description = "Map of instance names to instance IDs"
  value       = { for k, v in aws_instance.this : k => v.id }
}

output "instance_arns" {
  description = "Map of instance names to instance ARNs"
  value       = { for k, v in aws_instance.this : k => v.arn }
}

output "instance_public_ips" {
  description = "Map of instance names to public IPs"
  value       = { for k, v in aws_instance.this : k => v.public_ip }
}

output "instance_private_ips" {
  description = "Map of instance names to private IPs"
  value       = { for k, v in aws_instance.this : k => v.private_ip }
}

output "instance_public_dns" {
  description = "Map of instance names to public DNS names"
  value       = { for k, v in aws_instance.this : k => v.public_dns }
}

output "instance_private_dns" {
  description = "Map of instance names to private DNS names"
  value       = { for k, v in aws_instance.this : k => v.private_dns }
}

output "key_pair_names" {
  description = "Map of instance names to key pair names"
  value       = { for k, v in aws_key_pair.this : k => v.key_name }
}

output "private_keys" {
  description = "Map of instance names to private keys (PEM format)"
  value       = { for k, v in tls_private_key.this : k => v.private_key_pem }
  sensitive   = true
}

output "public_keys" {
  description = "Map of instance names to public keys (OpenSSH format)"
  value       = { for k, v in tls_private_key.this : k => v.public_key_openssh }
}

# Instance profile names
output "instance_profile_names" {
  description = "IAM instance profile names created by this module"
  value = {
    for k, v in aws_iam_instance_profile.this : k => v.name
  }
}

# Instance profile ARNs
output "instance_profile_arns" {
  description = "IAM instance profile ARNs created by this module"
  value = {
    for k, v in aws_iam_instance_profile.this : k => v.arn
  }
}

output "instances" {
  description = "Complete EC2 instance objects"
  value       = aws_instance.this
}
