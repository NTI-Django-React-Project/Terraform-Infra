# ───────────────────────────────
# EKS Network
# ───────────────────────────────
output "vpc_id" {
  value = module.stand_alone_jenkins_network.vpc_id
}

output "subnet_ids" {
  value = module.stand_alone_jenkins_network.subnet_ids
}

output "internet_gateway_id" {
  value = module.stand_alone_jenkins_network.internet_gateway_id
}

output "nat_gateway_ids" {
  value = module.stand_alone_jenkins_network.nat_gateway_ids
}

output "route_table_ids" {
  value = module.stand_alone_jenkins_network.route_table_ids
}

# ───────────────────────────────
# Security Groups
# ───────────────────────────────
output "security_group_ids" {
  description = "All SG name → ID pairs"
  value       = module.sg.security_group_ids
}

# ───────────────────────────────
# Jenkins
# ───────────────────────────────
output "jenkins_public_ip" {
  description = "Jenkins public IP"
  value       = module.ec2.instance_public_ips["stand-alone-jenkins-server"]
}

output "jenkins_url" {
  description = "Jenkins web UI"
  value       = "http://${module.ec2.instance_public_ips["stand-alone-jenkins-server"]}:8080"
}

output "jenkins_ssh_command" {
  description = "Ready-to-paste SSH command for Jenkins"
  value       = "ssh -i ./keys/jenkins-server-private-key.pem ec2-user@${module.ec2.instance_public_ips["stand-alone-jenkins-server"]}"
}
