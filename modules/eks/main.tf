# ───────────────────────────────
# EKS Cluster
# ───────────────────────────────
resource "aws_eks_cluster" "this" {
  for_each = var.clusters

  name     = each.key
  role_arn = each.value.cluster_role_arn
  version  = each.value.kubernetes_version

  vpc_config {
    subnet_ids              = each.value.subnet_ids
    endpoint_private_access = lookup(each.value, "endpoint_private_access", true)
    endpoint_public_access  = lookup(each.value, "endpoint_public_access", true)
    public_access_cidrs     = lookup(each.value, "public_access_cidrs", ["0.0.0.0/0"])
  }

  enabled_cluster_log_types = lookup(each.value, "enabled_cluster_log_types", ["api", "audit", "authenticator", "controllerManager", "scheduler"])

  tags = merge(var.tags, each.value.tags)
}

# ───────────────────────────────
# EKS Node Groups
# ───────────────────────────────
locals {
  # Flatten node groups across all clusters
  node_groups = flatten([
    for cluster_name, cluster_config in var.clusters : [
      for ng_name, ng_config in cluster_config.node_groups : merge(ng_config, {
        cluster_name    = cluster_name
        node_group_name = ng_name
        node_role_arn   = cluster_config.node_role_arn
      })
    ]
  ])
}

resource "aws_eks_node_group" "this" {
  for_each = { for ng in local.node_groups : "${ng.cluster_name}-${ng.node_group_name}" => ng }

  cluster_name    = aws_eks_cluster.this[each.value.cluster_name].name
  node_group_name = each.value.node_group_name
  node_role_arn   = each.value.node_role_arn
  subnet_ids      = each.value.subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  update_config {
    max_unavailable = each.value.max_unavailable
  }

  labels = each.value.labels

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${each.value.cluster_name}-${each.value.node_group_name}"
    }
  )

  depends_on = [aws_eks_cluster.this]
}
