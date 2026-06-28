variable "project" {}
variable "input_bucket" {}
variable "output_bucket" {}
variable "error_bucket" {}
variable "retention_days" {}

locals {
  tags = {
    Project = var.project
  }
}

resource "aws_s3_bucket" "input" {
  bucket = var.input_bucket
  tags   = merge(local.tags, { Purpose = "input" })
}

resource "aws_s3_bucket" "output" {
  bucket = var.output_bucket
  tags   = merge(local.tags, { Purpose = "output" })
}

resource "aws_s3_bucket" "error" {
  bucket = var.error_bucket
  tags   = merge(local.tags, { Purpose = "error" })
}

resource "aws_s3_bucket_lifecycle_configuration" "input" {
  bucket = aws_s3_bucket.input.id

  rule {
    id     = "expire-old"
    status = "Enabled"

    expiration {
      days = var.retention_days
    }
  }
}

output "input_bucket_name" {
  value = aws_s3_bucket.input.bucket
}

output "input_bucket_arn" {
  value = aws_s3_bucket.input.arn
}

output "output_bucket_name" {
  value = aws_s3_bucket.output.bucket
}

output "output_bucket_arn" {
  value = aws_s3_bucket.output.arn
}

output "error_bucket_name" {
  value = aws_s3_bucket.error.bucket
}

output "error_bucket_arn" {
  value = aws_s3_bucket.error.arn
}
