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

# Gerar sufixo aleatório para nomes dos buckets
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket" "input" {
  bucket = "${var.input_bucket}-${random_id.bucket_suffix.hex}"
  tags   = merge(local.tags, { Purpose = "input" })

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "output" {
  bucket = "${var.output_bucket}-${random_id.bucket_suffix.hex}"
  tags   = merge(local.tags, { Purpose = "output" })

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "error" {
  bucket = "${var.error_bucket}-${random_id.bucket_suffix.hex}"
  tags   = merge(local.tags, { Purpose = "error" })

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "input" {
  bucket              = aws_s3_bucket.input.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "output" {
  bucket              = aws_s3_bucket.output.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "error" {
  bucket              = aws_s3_bucket.error.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
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
