# 🏗️ Hướng Dẫn Sử Dụng Terraform Boilerplate (Mẫu Chuẩn)

Thư mục này chứa các "khung xương" giúp bạn mở rộng hạ tầng Kicks-Shoes hoặc bắt đầu dự án mới một cách nhanh chóng và đúng tiêu chuẩn.

## 1. Cách tạo một Module mới (VD: tạo thêm Redis)
1. Copy thư mục `templates/module_skeleton` vào `infrastructure/modules/redis`.
2. Sửa code trong `main.tf` để định nghĩa tài nguyên Redis.
3. Khai báo các biến cần thiết trong `variables.tf`.

## 2. Cách tạo một Môi trường mới (VD: tạo môi trường Production)
1. Copy thư mục `templates/environment_skeleton` vào `infrastructure/environments/prod`.
2. Mở `providers.tf` và sửa `key = "prod/terraform.tfstate"` để không bị ghi đè lên môi trường `dev`.
3. Mở `terraform.tfvars` và điền các thông số thực tế cho Production.
4. Chạy `terraform init` và `terraform apply`.
