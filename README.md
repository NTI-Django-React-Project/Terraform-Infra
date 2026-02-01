# Kubernetes Infrastructure on AWS

This project deploys a complete Kubernetes infrastructure on AWS in the `eu-north-1` region using Terraform.

## 📋 Infrastructure Overview

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        VPC (10.10.0.0/16)                                │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  eu-north-1b (Public Subnet 10.10.1.0/24)                       │    │
│  │  ┌──────────────────┐    ┌──────────────────┐                   │    │
│  │  │  Jenkins Server  │    │   NAT Gateway    │                   │    │
│  │  │   (t3.micro)     │    │   + Elastic IP   │                   │    │
│  │  │  jenkins-sg      │    │                  │                   │    │
│  │  └──────────────────┘    └──────────────────┘                   │    │
│  │           ↕                        ↕                             │    │
│  │     Internet Gateway                                             │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  eu-north-1a (Private Subnets)                                  │    │
│  │  ┌──────────────────┐    ┌──────────────────┐                   │    │
│  │  │  K8s Worker Node │    │   RDS Instance   │                   │    │
│  │  │   (t3.micro)     │    │   (Multi-AZ)     │                   │    │
│  │  │ 10.10.3.0/24     │    │  10.10.2.0/24    │                   │    │
│  │  │    k8s-sg        │    │    rds-sg        │                   │    │
│  │  └──────────────────┘    └──────────────────┘                   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  eu-north-1b (Private Subnet 10.10.4.0/24)                      │    │
│  │  ┌──────────────────┐                                            │    │
│  │  │  K8s Worker Node │                                            │    │
│  │  │   (t3.micro)     │                                            │    │
│  │  │    k8s-sg        │                                            │    │
│  │  └──────────────────┘                                            │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  eu-north-1c (Private Subnet 10.10.5.0/24)                      │    │
│  │  ┌──────────────────┐                                            │    │
│  │  │  K8s Worker Node │                                            │    │
│  │  │   (t3.micro)     │                                            │    │
│  │  │    k8s-sg        │                                            │    │
│  │  └──────────────────┘                                            │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  ECR Repositories                                                │    │
│  │  • app-frontend                                                  │    │
│  │  • app-backend                                                   │    │
│  │  • app-worker                                                    │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Resources Deployed

| Resource Type | Count | Details |
|---------------|-------|---------|
| **VPC** | 1 | 10.10.0.0/16 |
| **Subnets** | 6 | 1 public, 5 private across 3 AZs |
| **Internet Gateway** | 1 | For public subnet internet access |
| **NAT Gateway** | 1 | For private subnet internet access |
| **Route Tables** | 3 | Public, Private, Database |
| **Security Groups** | 3 | Jenkins, K8s, RDS |
| **EC2 Instances** | 4 | 1 Jenkins + 3 K8s nodes |
| **RDS Instance** | 1 | PostgreSQL Multi-AZ |
| **ECR Repositories** | 3 | Frontend, Backend, Worker |

### Subnet Layout

| Subnet | CIDR | AZ | Type | Purpose |
|--------|------|-------|------|---------|
| public-1b | 10.10.1.0/24 | eu-north-1b | Public | Jenkins, NAT Gateway |
| private-db-1a | 10.10.2.0/24 | eu-north-1a | Private | RDS Primary |
| private-k8s-1a | 10.10.3.0/24 | eu-north-1a | Private | K8s Worker |
| private-k8s-1b | 10.10.4.0/24 | eu-north-1b | Private | K8s Worker |
| private-k8s-1c | 10.10.5.0/24 | eu-north-1c | Private | K8s Worker |
| private-db-1b | 10.10.6.0/24 | eu-north-1b | Private | RDS Standby |

### Security Group Rules

**Jenkins SG:**
- Inbound: SSH (22), Jenkins Web (8080) from anywhere
- Outbound: All traffic

**K8s SG:**
- Inbound: SSH (22) from anywhere, All traffic from Jenkins SG
- Outbound: All traffic

**RDS SG:**
- Inbound: PostgreSQL (5432) from VPC (10.10.0.0/16)
- Outbound: None

## 🚀 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **SSH client** for connecting to instances

## 📦 Installation

### 1. Clone and Navigate

```bash
git clone <your-repo>
cd infrastructure-project
```

### 2. Configure Variables

```bash
# Copy example tfvars
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Important:** Change the `db_password` to a secure password!

### 3. Get Latest AMI ID (Optional)

Find the latest Amazon Linux 2 AMI in eu-north-1:

```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --region eu-north-1 \
  --query 'Images[*].[ImageId,CreationDate,Name]' \
  --output table | sort -k2 -r | head
```

Update `ami_id` in `terraform.tfvars`.

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review Plan

```bash
terraform plan
```

### 6. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted.

## 🔑 Accessing Resources

### SSH Keys

SSH private keys are automatically generated and stored in `./keys/` directory:

- `jenkins-server-private-key.pem`
- `k8s-node-1a-private-key.pem`
- `k8s-node-1b-private-key.pem`
- `k8s-node-1c-private-key.pem`

### Connect to Jenkins

```bash
# Get Jenkins public IP
terraform output jenkins_public_ip

# SSH to Jenkins
ssh -i ./keys/jenkins-server-private-key.pem ec2-user@<JENKINS_PUBLIC_IP>

# Access Jenkins web interface
# http://<JENKINS_PUBLIC_IP>:8080

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Connect to K8s Nodes (via Jenkins)

Since K8s nodes are in private subnets, you need to use Jenkins as a jump host:

```bash
# Copy private key to Jenkins server
scp -i ./keys/jenkins-server-private-key.pem \
    ./keys/k8s-node-1a-private-key.pem \
    ec2-user@<JENKINS_PUBLIC_IP>:~/

# SSH to Jenkins
ssh -i ./keys/jenkins-server-private-key.pem ec2-user@<JENKINS_PUBLIC_IP>

# From Jenkins, SSH to K8s node
ssh -i ~/k8s-node-1a-private-key.pem ec2-user@<K8S_PRIVATE_IP>
```

### Database Connection

```bash
# Get RDS endpoint
terraform output rds_endpoint

# Connect from K8s nodes or Jenkins
psql -h <RDS_ENDPOINT> -U dbadmin -d appdb
```

## 📊 Outputs

View all outputs:

```bash
terraform output
```

Important outputs:

```bash
# Jenkins access
terraform output jenkins_url
terraform output jenkins_public_ip

# K8s node IPs
terraform output k8s_node_private_ips

# Database
terraform output rds_address

# ECR repositories
terraform output ecr_repository_urls

# Infrastructure summary
terraform output infrastructure_summary
```

## 🔄 Making Changes

After modifying Terraform files:

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply changes
terraform apply
```

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

**Note:** This will delete all resources including the database. Make sure to backup any important data first!

## 📁 Project Structure

```
infrastructure-project/
├── provider.tf              # Provider configuration
├── variables.tf             # Input variables
├── main.tf                  # Main infrastructure code
├── outputs.tf               # Output values
├── terraform.tfvars.example # Example variables file
├── .gitignore              # Git ignore file
├── README.md               # This file
├── keys/                   # SSH keys (generated, gitignored)
└── modules/                # Terraform modules
    ├── vpc/
    ├── subnet/
    ├── nat-gateway/
    ├── internet-gateway/
    ├── route-table/
    ├── route-table-association/
    ├── security-group/
    ├── ec2/
    ├── rds/
    └── ecr/
```

## 🔒 Security Considerations

### ✅ Implemented

- RDS in private subnets (isolated)
- RDS Multi-AZ for high availability
- Encrypted RDS storage
- K8s nodes in private subnets
- NAT Gateway for private subnet internet access
- Security groups with minimal required access
- SSH key-based authentication
- Separate security groups per service

### ⚠️ Production Recommendations

1. **Secrets Management:**
   - Use AWS Secrets Manager for database passwords
   - Don't commit `terraform.tfvars` to git
   - Rotate credentials regularly

2. **Network Security:**
   - Restrict SSH access to specific IPs
   - Use VPN or bastion host for private resource access
   - Enable VPC Flow Logs

3. **Monitoring:**
   - Enable CloudWatch monitoring
   - Set up CloudWatch alarms
   - Enable RDS performance insights

4. **Backup:**
   - Configure RDS automated backups (already enabled - 7 days)
   - Enable RDS final snapshot before deletion
   - Backup EC2 volumes using snapshots

5. **Access Control:**
   - Implement IAM roles for EC2 instances
   - Use instance profiles instead of access keys
   - Apply principle of least privilege

## 💰 Cost Estimation (Monthly)

Approximate costs in eu-north-1:

| Resource | Type | Quantity | Cost/Month |
|----------|------|----------|------------|
| EC2 | t3.micro | 4 | ~$30 |
| RDS | db.t3.micro (Multi-AZ) | 1 | ~$40 |
| NAT Gateway | - | 1 | ~$35 |
| Elastic IP | - | 1 | ~$4 |
| EBS Storage | gp3 | ~120 GB | ~$15 |
| Data Transfer | - | varies | ~$10 |
| **Total** | | | **~$134** |

*Costs are estimates and may vary based on usage and AWS pricing changes.*

## 🛠️ Troubleshooting

### Terraform Errors

**Error: Invalid AMI**
- Update AMI ID in `terraform.tfvars` for your region

**Error: Insufficient capacity**
- Try different instance type or availability zone

**Error: VPC limit exceeded**
- Delete unused VPCs or request limit increase

### Connection Issues

**Can't SSH to Jenkins:**
- Check security group allows SSH from your IP
- Verify key permissions: `chmod 400 ./keys/*.pem`
- Check instance is running: `terraform output ec2_instance_ids`

**Can't access Jenkins web interface:**
- Wait 5-10 minutes after deployment for Jenkins to start
- Check security group allows port 8080
- Verify public IP: `terraform output jenkins_public_ip`

**Can't connect to RDS:**
- Ensure you're connecting from within VPC (K8s nodes or Jenkins)
- Verify security group allows PostgreSQL (5432) from source
- Check RDS endpoint: `terraform output rds_endpoint`

### Module Errors

**Error: Module not found**
- Ensure modules are in `./modules/` directory
- Run `terraform init` to initialize modules

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Amazon RDS Documentation](https://docs.aws.amazon.com/rds/)
- [Amazon ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)

## 📝 Notes

- All resources are tagged with Project, Environment, and ManagedBy tags
- SSH keys are auto-generated using TLS provider
- Private keys are stored in `./keys/` (gitignored)
- Database password is sensitive and must be changed from default
- NAT Gateway is required for private subnets to access internet
- Multi-AZ RDS provides automatic failover

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is provided as-is for infrastructure automation purposes.
