# ---------------------------------------------------------------------------------------------------------------------
# PROVIDERS - Cấu hình cho môi trường DEV
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # THIẾT LẬP BACKEND (QUAN TRỌNG):
  # Mặc định Terraform lưu trạng thái (state) ở local (file terraform.tfstate).
  # Để làm việc nhóm, bạn nên sử dụng S3 Backend để lưu trữ state an toàn.
  # backend "s3" {
  #   bucket         = "kicks-shoes-tf-state"
  #   key            = "environments/dev/terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "terraform-locks" # Dùng để khóa state (tránh xung đột)
  # }
}

provider "aws" {
  region = var.aws_region

  # THIẾT LẬP PROFILE:
  # Nếu bạn có nhiều tài khoản AWS, hãy bỏ comment dòng dưới và điền tên profile (từ ~/.aws/credentials)
  # profile = "my-aws-profile"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

