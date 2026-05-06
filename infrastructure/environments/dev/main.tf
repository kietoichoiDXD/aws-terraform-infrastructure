# ==============================================================================
# PROJECT: Kicks-Shoes AWS Infrastructure (Production-Ready Boilerplate)
# FILE: environments/dev/main.tf
# CHỨC NĂNG: Đây là file "Nhạc Trưởng". Nó gọi các Module hạ tầng và kết nối
#            chúng lại với nhau để tạo thành một hệ thống hoàn chỉnh.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. KHỞI TẠO HỆ THỐNG MẠNG (Networking)
# Thiết lập VPC, Subnets, Internet Gateway và NAT Gateway.
# Đây là hạ tầng cơ sở, cung cấp dải IP cho toàn bộ dự án.
# ------------------------------------------------------------------------------
module "network" {
  source = "../../modules/network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ------------------------------------------------------------------------------
# 2. QUẢN LÝ DANH TÍNH & QUYỀN HẠN (IAM)
# Tạo các IAM Role cho phép ECS Fargate có quyền thực thi:
# - Task Execution Role: Dùng để kéo Image từ ECR và ghi Log vào CloudWatch.
# - Task Role: Dùng cho code ứng dụng để truy cập S3/DynamoDB.
# ------------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

# ------------------------------------------------------------------------------
# 3. BỘ CÂN BẰNG TẢI (Load Balancer)
# Tạo Application Load Balancer (ALB) nằm ở Public Subnet.
# ALB đóng vai trò "cửa ngõ" bảo mật, điều phối traffic từ khách hàng vào App.
# ------------------------------------------------------------------------------
module "load_balancer" {
  source = "../../modules/load_balancer"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  container_port    = var.container_port
}

# ------------------------------------------------------------------------------
# 4. TRIỂN KHAI CONTAINER (ECS Fargate)
# Nơi ứng dụng Backend của bạn thực sự vận hành.
# Toàn bộ container được đặt trong Private Subnet (Không thể truy cập trực tiếp).
# ------------------------------------------------------------------------------
module "ecs" {
  source = "../../modules/ecs"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  vpc_id                = module.network.vpc_id
  private_subnet_ids    = module.network.private_subnet_ids
  alb_security_group_id = module.load_balancer.alb_security_group_id
  target_group_arn      = module.load_balancer.target_group_arn
  alb_listener_arn      = module.load_balancer.alb_listener_arn # Quản lý thứ tự triển khai
  
  execution_role_arn    = module.iam.ecs_task_execution_role_arn
  task_role_arn         = module.iam.ecs_task_role_arn
  
  container_image       = var.container_image
  container_port        = var.container_port
  cpu                   = var.cpu
  memory                = var.memory
  desired_count         = var.desired_count

  # Truyền biến môi trường cho ứng dụng
  environment_variables = [
    { name = "NODE_ENV", value = var.environment },
    { name = "PORT", value = tostring(var.container_port) }
  ]
}

# ------------------------------------------------------------------------------
# 5. CƠ SỞ DỮ LIỆU (NoSQL DynamoDB)
# Thiết lập bảng dữ liệu cho ứng dụng.
# ------------------------------------------------------------------------------
module "database" {
  source = "../../modules/database"

  project_name = var.project_name
  environment  = var.environment
}

# ------------------------------------------------------------------------------
# 6. LƯU TRỮ TỆP TIN (S3 Storage)
# Tạo bucket để lưu trữ ảnh sản phẩm, tài liệu...
# ------------------------------------------------------------------------------
module "storage_assets" {
  source = "../../modules/storage"

  project_name  = var.project_name
  environment   = var.environment
  bucket_name   = "assets"
  force_destroy = true # Cho phép xóa bucket kể cả khi có file (cẩn thận!)
}
