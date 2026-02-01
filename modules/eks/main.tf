terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  for_each = var.clusters

  name = "${each.key}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${each.key}-cluster-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  for_each = var.clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[each.key].name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  for_each = var.clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster[each.key].name
}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  for_each = var.clusters

  name     = each.key
  role_arn = aws_iam_role.cluster[each.key].arn
  version  = lookup(each.value, "kubernetes_version", "1.28")

  vpc_config {
    subnet_ids              = each.value.subnet_ids
    endpoint_private_access = lookup(each.value, "endpoint_private_access", true)
    endpoint_public_access  = lookup(each.value, "endpoint_public_access", true)
    public_access_cidrs     = lookup(each.value, "public_access_cidrs", ["0.0.0.0/0"])
    security_group_ids      = lookup(each.value, "security_group_ids", [])
  }

  enabled_cluster_log_types = lookup(each.value, "enabled_cluster_log_types", ["api", "audit", "authenticator", "controllerManager", "scheduler"])

  encryption_config {
    provider {
      key_arn = lookup(each.value, "kms_key_arn", null)
    }
    resources = ["secrets"]
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_resource_controller
  ]
}

# Node Group IAM Role
resource "aws_iam_role" "node_group" {
  for_each = var.clusters

  name = "${each.key}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${each.key}-node-group-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "node_group_worker_policy" {
  for_each = var.clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  for_each = var.clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_group_ecr_policy" {
  for_each = var.clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group[each.key].name
}

# EKS Node Groups
resource "aws_eks_node_group" "this" {
  for_each = {
    for item in local.node_groups : "${item.cluster_name}-${item.node_group_name}" => item
  }

  cluster_name    = aws_eks_cluster.this[each.value.cluster_name].name
  node_group_name = each.value.node_group_name
  node_role_arn   = aws_iam_role.node_group[each.value.cluster_name].arn
  subnet_ids      = each.value.subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  instance_types = each.value.instance_types
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")
  disk_size      = lookup(each.value, "disk_size", 20)

  update_config {
    max_unavailable = lookup(each.value, "max_unavailable", 1)
  }

  labels = lookup(each.value, "labels", {})

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = "${each.value.cluster_name}-${each.value.node_group_name}"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_ecr_policy
  ]
}

locals {
  # Flatten node groups
  node_groups = flatten([
    for cluster_name, cluster_config in var.clusters : [
      for ng_name, ng_config in lookup(cluster_config, "node_groups", {}) : merge(ng_config, {
        cluster_name     = cluster_name
        node_group_name  = ng_name
      })
    ]
  ])
}
