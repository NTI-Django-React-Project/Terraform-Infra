# ────────────────────────────── IAM OIDC Provider (skip if already exists) ──────────────────────────────
data "tls_certificate" "eks_oidc" {
  url = var.cluster_oidc_issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  # Only create if OIDC provider doesn't exist
  count = var.create_oidc_provider ? 1 : 0
  
  url             = var.cluster_oidc_issuer  # Full URL from EKS
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  
  tags = merge(var.tags, {
        Region  = var.region  # ← Use variable for tagging
        Name = "oidc-${var.cluster_name}"
  })
}


# Use existing OIDC provider or get from data source
data "aws_iam_openid_connect_provider" "existing" {
  count = var.create_oidc_provider ? 0 : 1
  
  url = var.cluster_oidc_issuer
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.oidc_provider[0].arn : data.aws_iam_openid_connect_provider.existing[0].arn
  oidc_issuer_without_protocol = replace(var.cluster_oidc_issuer, "https://", "")
}


# ────────────────────────────── IAM Roles for IRSA ──────────────────────────────
resource "aws_iam_role" "irsa" {
  for_each = var.service_accounts

  name        = each.value.role_name
  description = "IRSA role for ${each.key} service account"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_without_protocol}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.k8s_sa_name}"
          "${local.oidc_issuer_without_protocol}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  
  tags = merge(var.tags, {
    ServiceAccount = each.key
    Namespace      = each.value.namespace
    ManagedBy      = "terraform"
  })
}
# ────────────────────────────── IAM Policies for IRSA ──────────────────────────────
resource "aws_iam_policy" "irsa_policy" {
  for_each = var.service_accounts

  name        = each.value.policy_name
  description = "IRSA policy for ${each.key}"
  policy      = jsonencode(each.value.policy_document)
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "irsa_attach" {
  for_each = var.service_accounts

  role       = aws_iam_role.irsa[each.key].name
  policy_arn = aws_iam_policy.irsa_policy[each.key].arn
}

# ────────────────────────────── Kubernetes Service Accounts ──────────────────────────────
resource "kubernetes_service_account_v1" "sa" {
  for_each = var.service_accounts

  metadata {
    name      = each.value.k8s_sa_name
    namespace = each.value.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa[each.key].arn
    }
    labels = {
      managed-by = "terraform"
    }
  }
  
  automount_service_account_token = true
}