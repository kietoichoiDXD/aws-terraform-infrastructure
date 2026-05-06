variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "container_port" {
  description = "Cổng mà container ứng dụng đang chạy (ví dụ 3000)"
  type        = number
  default     = 3000
}
