output "bucket_name" {
  description = "Encrypted, versioned S3 bucket for Terraform state."
  value       = aws_s3_bucket.terraform_state.bucket
}
