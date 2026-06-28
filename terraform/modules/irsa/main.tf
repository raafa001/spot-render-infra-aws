variable "cluster_oidc_provider_arn" {
  type = string
}

variable "service_accounts" {
  description = "Map of service accounts and bucket ARNs"
  type = map(object({
    namespace = string
    bucket_arn = string
  }))
}

locals {
  oidc = replace(var.cluster_oidc_provider_arn, "https://", "")
}

resource "aws_iam_role" "sa" {
  for_each = var.service_accounts

  name = "irsa-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.cluster_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc}:sub" = "system:serviceaccount:${each.value.namespace}:${each.key}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  for_each = var.service_accounts

  role = aws_iam_role.sa[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = [each.value.bucket_arn, "${each.value.bucket_arn}/*"]
    }]
  })
}

output "iam_roles" {
  value = aws_iam_role.sa
}
