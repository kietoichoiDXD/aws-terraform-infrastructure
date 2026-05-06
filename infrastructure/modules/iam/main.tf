# ---------------------------------------------------------------------------------------------------------------------
# IAM MODULE - Quản lý quyền truy cập cho hạ tầng Kicks-Shoes
# ---------------------------------------------------------------------------------------------------------------------

# 1. ECS Task Execution Role (Dùng để ECS Agent gọi AWS APIs: kéo image từ ECR, ghi logs)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-execution-role"
    Environment = var.environment
  }
}

# Attach policy chuẩn của AWS cho ECS Task Execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. ECS Task Role (Quyền dành riêng cho ứng dụng chạy bên trong Container - ví dụ: truy cập S3, DynamoDB)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-role"
    Environment = var.environment
  }
}

# 3. Custom Policy cho Task Role (Ví dụ: Cho phép app đọc/ghi DynamoDB và S3)
resource "aws_iam_policy" "task_custom_policy" {
  name        = "${var.project_name}-${var.environment}-task-custom-policy"
  description = "Quyền truy cập resource AWS cho backend Kicks-Shoes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = "*" # Trong production nên giới hạn ARN cụ thể của table
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = "*" # Trong production nên giới hạn ARN cụ thể của bucket
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_custom_policy_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_custom_policy.arn
}
