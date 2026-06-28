variable "cluster_name" {}
variable "domain" {}

resource "aws_wafv2_web_acl" "this" {
  name        = "${var.cluster_name}-waf"
  description = "WAF for Spot Render ingress"
  scope       = "REGIONAL"
  default_action { allow {} }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "spot-render-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "limit-requests"
    priority = 1
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    action { block {} }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "limit"
      sampled_requests_enabled   = true
    }
  }
}

# Ingress resources são aplicados no repositório de manifests; este módulo apenas expõe o ARN do WAF.

output "waf_arn" {
  value = aws_wafv2_web_acl.this.arn
}
