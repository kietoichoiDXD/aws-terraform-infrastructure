# ---------------------------------------------------------------------------------------------------------------------
# MODULE: STORAGE - Quản lý S3 Buckets
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket        = "${var.project_name}-${var.bucket_name}-${var.environment}"
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Component = "Storage"
  })
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
