# ---------------------------------------------------------------------------------------------------------------------
# MAIN - Ghép nối các Module để tạo nên hạ tầng hoàn chỉnh
# ---------------------------------------------------------------------------------------------------------------------

# 1. Triển khai Module Network
module "network" {
  source = "../../modules/network"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
}

# 2. Triển khai Module Database
module "database" {
  source = "../../modules/database"

  project_name = var.project_name
  environment  = var.environment
}

# 3. Triển khai Module Storage (S3 cho Assets)
module "storage_assets" {
  source = "../../modules/storage"

  project_name  = var.project_name
  environment   = var.environment
  bucket_name   = "assets"
  force_destroy = true
}

# 4. Triển khai Module Storage (S3 cho Logs)
module "storage_logs" {
  source = "../../modules/storage"

  project_name  = var.project_name
  environment   = var.environment
  bucket_name   = "logs"
  force_destroy = true
}
