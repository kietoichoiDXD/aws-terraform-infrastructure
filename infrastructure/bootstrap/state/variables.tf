variable "aws_region" {
  description = "Region for the Terraform state bucket. Keep it in an enabled AWS Region."
  type        = string
  default     = "ap-southeast-1"
}
