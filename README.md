# 🚀 Kicks-Shoes AWS Professional Terraform Boilerplate

Đây không chỉ là một dự án hạ tầng, mà là một **Bộ Khung (Boilerplate) Chuẩn Công Nghiệp** để triển khai các ứng dụng lên AWS một cách chuyên nghiệp, an toàn và dễ dàng mở rộng.

## 🌟 Điểm Nổi Bật (Key Features)

1.  **Thiết Kế Modular 100%**: Mỗi thành phần (Network, IAM, ECS, DB) là một module độc lập, dễ dàng cắm rút và tái sử dụng cho các dự án khác.
2.  **Bảo Mật Đa Tầng (Deep Security)**: 
    *   Sử dụng **Private Subnets** cho ứng dụng, ngăn chặn mọi truy cập trực tiếp từ Internet.
    *   **IAM Roles** được cấu hình theo nguyên tắc "đặc quyền tối thiểu" (Least Privilege).
    *   **ALB** đóng vai trò cổng bảo mật duy nhất.
3.  **Dễ Hiểu & Dễ Bảo Trì**: Toàn bộ code được chú thích chi tiết bằng tiếng Việt, giúp các thành viên mới nắm bắt hệ thống chỉ trong vài phút.
4.  **Tối Ưu Chi Phí**: Thiết kế thông minh giúp tiết kiệm chi phí trong môi trường Development (như dùng chung NAT Gateway).
5.  **Sẵn Sàng Cho Production**: Cấu hình Remote State (S3 + DynamoDB) giúp làm việc nhóm an toàn và chuyên nghiệp.

---

## 📂 Cấu Trúc File Chi Tiết (Project Blueprint)

```text
infrastructure/
├── modules/                # THƯ VIỆN MODULES (Gạch xây nhà)
│   ├── network/            # Tạo VPC, Subnets, NAT Gateway (Nền móng mạng)
│   ├── load_balancer/      # ALB & Target Groups (Cửa ngõ traffic)
│   ├── ecs/                # ECS Cluster & Fargate Service (Nơi chạy App)
│   ├── iam/                # Phân quyền IAM (Chìa khóa bảo mật)
│   ├── database/           # DynamoDB (Cơ sở dữ liệu)
│   └── storage/            # S3 Buckets (Lưu trữ file)
├── environments/           # CẤU HÌNH MÔI TRƯỜNG (Hoàn thiện nhà)
│   └── dev/                # Môi trường Development (Mẫu chuẩn)
│       ├── main.tf         # File "Nhạc Trưởng" kết nối các module
│       ├── terraform.tfvars # Nơi điền thông số thực tế
│       └── providers.tf    # Cấu hình AWS & Remote Backend
├── scripts/                # CÔNG CỤ HỖ TRỢ
│   └── check.sh            # Script tự động kiểm tra code (Validate & Format)
└── docs/                   # TÀI LIỆU VẬN HÀNH
```

---

## 🛠️ Hướng Dẫn Triển Khai Nhanh (Quick Start)

### 1. Chuẩn bị
*   Cài đặt **Terraform** và **AWS CLI**.
*   Có quyền truy cập vào tài khoản AWS của bạn.

### 2. Cấu hình
Mở file `infrastructure/environments/dev/terraform.tfvars` và chỉnh sửa các giá trị:
*   `aws_region`: Vùng AWS bạn muốn dùng (mặc định: ap-southeast-1).
*   `container_image`: Link image Docker của bạn.

### 3. Thực thi
```bash
# Di chuyển vào thư mục môi trường
cd infrastructure/environments/dev

# Khởi tạo (Download thư viện & Backend)
terraform init

# Kiểm tra code
terraform plan

# Triển khai thực tế
terraform apply
```

---

## 📖 Hệ Thống Tài Liệu (Documentation)
*   [Kiến Trúc Hệ Thống](infrastructure/docs/ARCHITECTURE_GUIDE.md)
*   [Hướng Dẫn Triển Khai](infrastructure/docs/DEPLOYMENT_GUIDE.md)
*   [Xử Lý Lỗi Thường Gặp](infrastructure/docs/TROUBLESHOOTING.md)

---
*Chúc bạn xây dựng hạ tầng thành công! Dự án được tinh chỉnh và đóng gói bởi Antigravity AI.*
