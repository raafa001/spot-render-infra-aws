variable "project" {}
variable "secrets" { type = map(string) }

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name = "${var.project}/${each.key}"
  tags = {
    Project = var.project
  }
}

resource "aws_secretsmanager_secret_version" "value" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value
}

output "secret_arns" {
  value = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}
