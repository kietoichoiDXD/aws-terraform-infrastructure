# Hệ Thống Quản Lý Hạ Tầng Chuyên Nghiệp - Kicks Shoes AWS

Chào mừng bạn đến với cấu trúc thư mục Terraform tiêu chuẩn công nghiệp (Production-Ready). Cấu trúc này giúp quản lý hạ tầng lớn một cách dễ dàng, bảo mật và có khả năng mở rộng cao.

## 1. Cấu Trúc Thư Mục (Directory Structure)

```text
infrastructure/
├── modules/                # Chứa các khối hạ tầng có thể tái sử dụng
│   ├── network/            # Quản lý VPC, Subnet, Routing
│   ├── database/           # Quản lý DynamoDB, RDS
│   └── storage/            # Quản lý S3 Buckets
├── environments/           # Chứa cấu hình riêng cho từng môi trường
│   └── dev/                # Môi trường Development
│       ├── main.tf         # Nơi gọi các module và ghép nối chúng
│       ├── providers.tf    # Khai báo Provider và Backend
│       ├── variables.tf    # Khai báo các biến cho môi trường này
│       ├── outputs.tf      # Hiển thị kết quả triển khai
│       └── terraform.tfvars # Chứa giá trị thực tế của các biến
└── docs/                   # Tài liệu hướng dẫn
    └── TROUBLESHOOTING.md  # Cách xử lý các lỗi thường gặp
```

## 2. Tại sao cấu trúc này lại "Chuyên nghiệp"?

1.  **Tính Module hóa (Modularity)**: Bạn không viết tất cả vào một file. Mỗi thành phần (Network, DB, Storage) là một module riêng biệt. Điều này giúp dễ dàng bảo trì và kiểm thử.
2.  **Tách biệt môi trường (Isolation)**: Bạn có thể dễ dàng tạo thêm thư mục `prod` hoặc `staging` trong `environments/` mà không ảnh hưởng đến môi trường `dev`.
3.  **Quản lý biến chặt chẽ**: Sử dụng `terraform.tfvars` để tách biệt giữa "Định nghĩa biến" và "Giá trị thực tế".
4.  **Hỗ trợ làm việc nhóm**: Cấu trúc này cực kỳ thân thiện với Git. Các thành viên có thể làm việc trên các module khác nhau mà ít bị xung đột (conflict).

## 3. Các bước triển khai

Để bắt đầu, hãy đọc kỹ hướng dẫn tại: **[DEPLOYMENT_GUIDE.md](file:///d:/AWS/TF/infrastructure/docs/DEPLOYMENT_GUIDE.md)**.

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

---
*Hãy đọc file [TROUBLESHOOTING.md](file:///d:/AWS/TF/infrastructure/docs/TROUBLESHOOTING.md) nếu bạn gặp bất kỳ khó khăn nào trong quá trình triển khai!*

