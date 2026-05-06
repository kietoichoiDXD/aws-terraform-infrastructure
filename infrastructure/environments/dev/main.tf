# ---------------------------------------------------------------------------------------------------------------------
# MAIN - Ghép nối các Module để tạo nên hạ tầng hoàn chỉnh cho Kicks-Shoes
# ---------------------------------------------------------------------------------------------------------------------

# 1. Triển khai Module Network (VPC, Subnets, NAT GW)
module "network" {
  source = "../../modules/network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# 2. Triển khai Module IAM (Quyền truy cập cho ECS)
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

# 3. Triển khai Module Load Balancer (Cổng vào ứng dụng)
module "load_balancer" {
  source = "../../modules/load_balancer"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  container_port    = var.container_port
}

# 4. Triển khai Module ECS (Fargate Service)
module "ecs" {
  source = "../../modules/ecs"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  vpc_id                = module.network.vpc_id
  private_subnet_ids    = module.network.private_subnet_ids
  alb_security_group_id = module.load_balancer.alb_security_group_id
  target_group_arn      = module.load_balancer.target_group_arn
  alb_listener_arn      = module.load_balancer.alb_listener_arn # Dùng để quản lý dependency
  
  execution_role_arn    = module.iam.ecs_task_execution_role_arn
  task_role_arn         = module.iam.ecs_task_role_arn
  
  container_image       = var.container_image
  container_port        = var.container_port
  cpu                   = var.cpu
  memory                = var.memory
  desired_count         = var.desired_count

  # Ví dụ truyền biến môi trường
  environment_variables = [
    { name = "NODE_ENV", value = var.environment },
    { name = "PORT", value = tostring(var.container_port) }
  ]
}

# 5. Triển khai Module Database (DynamoDB)
module "database" {
  source = "../../modules/database"

  project_name = var.project_name
  environment  = var.environment
}

# 6. Triển khai Module Storage (S3 cho Assets)
module "storage_assets" {
  source = "../../modules/storage"

  project_name  = var.project_name
  environment   = var.environment
  bucket_name   = "assets"
  force_destroy = true
}
