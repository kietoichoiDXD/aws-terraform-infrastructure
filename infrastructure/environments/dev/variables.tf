# Biến chung
variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }

# Biến Network
variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "availability_zones" { type = list(string) }

# Biến ECS
variable "container_image" { type = string }
variable "container_port" {
  type    = number
  default = 3000
}
variable "cpu" { default = 256 }
variable "memory" { default = 512 }
variable "desired_count" { default = 1 }
