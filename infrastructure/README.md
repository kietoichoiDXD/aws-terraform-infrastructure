# Hệ Thống Quản Lý Hạ Tầng Chuyên Nghiệp - Kicks Shoes AWS

Chào mừng bạn đến với cấu trúc thư mục Terraform tiêu chuẩn công nghiệp (Production-Ready). Cấu trúc này giúp quản lý hạ tầng lớn một cách dễ dàng, bảo mật và có khả năng mở rộng cao cho dự án **Kicks-Shoes**.

## 1. Cấu Trúc Thư Mục (Directory Structure)

```text
infrastructure/
├── modules/                # Chứa các khối hạ tầng có thể tái sử dụng
│   ├── network/            # Quản lý VPC, Subnet (Public/Private), NAT Gateway
│   ├── load_balancer/      # Quản lý ALB, Target Groups, Listeners
│   ├── ecs/                # Quản lý ECS Cluster, Fargate Service, Task Definition
│   ├── iam/                # Quản lý IAM Roles & Policies (Execution/Task roles)
│   ├── database/           # Quản lý DynamoDB
│   └── storage/            # Quản lý S3 Buckets
├── environments/           # Chứa cấu hình riêng cho từng môi trường
│   └── dev/                # Môi trường Development
│       ├── main.tf         # Nơi ghép nối các module (Network, Compute, DB...)
│       ├── providers.tf    # Khai báo Provider và S3 Remote Backend
│       ├── variables.tf    # Khai báo các biến cho môi trường này
│       ├── outputs.tf      # Hiển thị kết quả triển khai (ALB DNS, Cluster Name...)
│       └── terraform.tfvars # Chứa giá trị thực tế của các biến
└── docs/                   # Thư viện tài liệu kỹ thuật
    ├── ARCHITECTURE_GUIDE.md      # Hướng dẫn chi tiết về kiến trúc hệ thống
    ├── BACKEND_OPERATIONS_GUIDE.md # Hướng dẫn vận hành và deploy backend
    ├── DEPLOYMENT_CHECKLIST.md     # Danh sách các bước kiểm tra trước/sau deploy
    ├── DEPLOYMENT_GUIDE.md         # Cách triển khai hạ tầng từ đầu
    ├── TERRAFORM_REGISTRY_GUIDE.md # Cách sử dụng & import module từ Registry
    └── TROUBLESHOOTING.md          # Cách xử lý các lỗi thường gặp
```

## 2. Tại sao cấu trúc này lại "Chuyên nghiệp"?

1.  **Tính Module hóa (Modularity)**: Mỗi thành phần hạ tầng được đóng gói riêng biệt. Bạn có thể thay đổi Network mà không làm ảnh hưởng đến ECS Service.
2.  **Tách biệt môi trường (Isolation)**: Dễ dàng mở rộng sang `prod` hoặc `staging` bằng cách nhân bản thư mục trong `environments/`.
3.  **Bảo mật tối ưu (Security)**: 
    *   Sử dụng **Private Subnets** cho ứng dụng backend (ECS Fargate).
    *   Sử dụng **IAM Roles** với nguyên tắc đặc quyền tối thiểu (Least Privilege).
    *   Quản lý **Remote State** tập trung trên S3 với khóa (Locking) qua DynamoDB.
4.  **Tích hợp CI/CD**: Cấu trúc này được thiết kế để hoạt động hoàn hảo với GitHub Actions hoặc GitLab CI.

## 3. Các bước triển khai

Để bắt đầu, hãy đọc kỹ hướng dẫn tại: **[DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)**.

Tóm tắt các bước:
1.  Di chuyển vào thư mục môi trường:
    ```bash
    cd infrastructure/environments/dev
    ```
2.  Khởi tạo dự án:
    ```bash
    terraform init
    ```
3.  Xem kế hoạch triển khai:
    ```bash
    terraform plan
    ```
4.  Áp dụng thay đổi:
    ```bash
    terraform apply
    ```

## 4. Tài liệu quan trọng cho Team
*   **Dành cho Backend**: [Hướng dẫn vận hành backend](docs/BACKEND_OPERATIONS_GUIDE.md)
*   **Dành cho DevOps**: [Kiến trúc hệ thống](docs/ARCHITECTURE_GUIDE.md)
*   **Dành cho Newbie**: [Cách dùng Terraform Registry](docs/TERRAFORM_REGISTRY_GUIDE.md)

---
*Chúc bạn triển khai hạ tầng thành công! Nếu gặp lỗi, hãy check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).*
