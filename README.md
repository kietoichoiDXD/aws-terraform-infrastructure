# 👟 Kicks-Shoes AWS Infrastructure (Terraform Professional)

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)

Chào mừng bạn đến với Repository quản lý hạ tầng đám mây cho dự án **Kicks-Shoes**. Đây là bộ code Terraform được xây dựng theo tiêu chuẩn công nghiệp (Production-Ready), sử dụng mô hình Module hóa để tối ưu quản lý, bảo mật và khả năng mở rộng.

---

## 📂 Cấu Trúc Dự Án (Project Structure)

Dự án được tổ chức theo cấu trúc phân cấp chuyên nghiệp:

```text
.
├── infrastructure/           # Thư mục chính chứa toàn bộ hạ tầng
│   ├── modules/              # Các thành phần hạ tầng có thể tái sử dụng
│   │   ├── network/          # VPC, Subnets, Internet Gateway, Routing
│   │   ├── database/         # DynamoDB Tables (NoSQL)
│   │   └── storage/          # S3 Buckets cho Assets và Logs
│   ├── environments/         # Cấu hình cụ thể cho từng môi trường
│   │   └── dev/              # Môi trường Development (Triển khai chính)
│   └── docs/                 # Tài liệu hướng dẫn chuyên sâu
│       ├── DEPLOYMENT_GUIDE.md  # Hướng dẫn cài đặt & triển khai chi tiết
│       └── TROUBLESHOOTING.md   # Các lỗi thường gặp và cách khắc phục
├── .gitignore                # Chặn các file nhạy cảm (tfstate, tfvars)
└── README.md                 # Tài liệu này
```

## 🚀 Các Tính Năng Nổi Bật

*   **Modular Architecture**: Chia nhỏ hạ tầng thành các khối (Network, Database, Storage) giúp dễ dàng bảo trì.
*   **Environment Separation**: Tách biệt hoàn toàn giữa code logic và thông số môi trường (Dev/Staging/Prod).
*   **Security First**: Chặn Public Access cho S3, bật Encryption cho DynamoDB và quản lý phiên bản (Versioning).
*   **Highly Scalable**: Dễ dàng thêm mới các thành phần như ECS, RDS, CloudFront vào cấu trúc hiện có.

## 🛠️ Yêu Cầu Hệ Thống

*   **Terraform CLI**: Phiên bản `>= 1.5.0`
*   **AWS CLI**: Đã được cấu hình (`aws configure`)
*   **Quyền IAM**: Quyền Administrator hoặc quyền quản lý VPC/S3/DynamoDB.

## 📖 Hướng Dẫn Nhanh (Quick Start)

1.  **Di chuyển vào môi trường Dev**:
    ```bash
    cd infrastructure/environments/dev
    ```
2.  **Khởi tạo**:
    ```bash
    terraform init
    ```
3.  **Kiểm tra & Triển khai**:
    ```bash
    terraform plan
    terraform apply
    ```

> [!IMPORTANT]
> Luôn đọc kỹ **[DEPLOYMENT_GUIDE.md](file:///d:/AWS/TF/infrastructure/docs/DEPLOYMENT_GUIDE.md)** trước khi bắt đầu triển khai lần đầu tiên.

## 🤝 Hỗ Trợ & Xử Lý Lỗi

Nếu gặp bất kỳ khó khăn nào trong quá trình chạy `terraform apply`, vui lòng tham khảo file **[TROUBLESHOOTING.md](file:///d:/AWS/TF/infrastructure/docs/TROUBLESHOOTING.md)** để tìm giải pháp cho các lỗi phổ biến nhất.

---
**Managed by Terraform | Project: Kicks-Shoes AWS**
