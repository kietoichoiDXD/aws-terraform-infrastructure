# 🚀 Kicks-Shoes AWS Professional Infrastructure

> **Standardized Terraform Boilerplate for High-Availability Microservices**

Chào mừng bạn đến với hệ thống hạ tầng của dự án **Kicks-Shoes**. Đây là bộ khung (boilerplate) chuẩn công nghiệp, được thiết kế để triển khai các ứng dụng lên AWS một cách chuyên nghiệp, an toàn và dễ dàng mở rộng.

---

## 🌟 Tính Năng Cốt Lõi (Key Features)

| Tính Năng | Mô Tả |
| :--- | :--- |
| **Modular 100%** | Kiến trúc module độc lập (Network, IAM, ECS, DB), dễ dàng tái sử dụng. |
| **Bảo Mật Đa Tầng** | Private Subnets, Least Privilege IAM, và ALB bảo vệ ứng dụng. |
| **CI/CD Tích Hợp** | Tự động hóa hoàn toàn qua GitHub Actions (Plan & Apply). |
| **Tối Ưu Chi Phí** | Chia sẻ tài nguyên thông minh (NAT Gateway) cho môi trường Dev. |
| **Remote State** | Quản lý trạng thái hạ tầng an toàn qua S3 + DynamoDB. |

---

## 🏗️ Kiến Trúc Hệ Thống (Project Blueprint)

```text
infrastructure/
├── modules/                # THƯ VIỆN MODULES (Gạch xây nhà)
│   ├── network/            # VPC, Subnets, NAT Gateway (Nền móng)
│   ├── load_balancer/      # ALB & Target Groups (Cửa ngõ)
│   ├── ecs/                # ECS Cluster & Fargate (Máy chủ App)
│   ├── iam/                # Phân quyền bảo mật (Chìa khóa)
│   ├── database/           # DynamoDB (Dữ liệu)
│   └── storage/            # S3 Buckets (Lưu trữ file)
├── environments/           # CẤU HÌNH MÔI TRƯỜNG (Hoàn thiện)
│   └── dev/                # Môi trường Development chuẩn
├── templates/              # BẢN VẼ MẪU (Skeletons)
│   ├── environment_skeleton # Dùng khi tạo môi trường mới (Prod/Staging)
│   └── module_skeleton      # Dùng khi tạo module mới (Redis/Kafka...)
└── docs/                   # TRUNG TÂM TÀI LIỆU
```

---

## 🚀 Bắt Đầu Nhanh (Quick Start)

### 1. Chuẩn Bị
*   Cài đặt **Terraform** v1.7+ và **AWS CLI**.
*   Cấu hình AWS Credentials với quyền Admin/PowerUser.

### 2. Triển Khai Thủ Công
```bash
cd infrastructure/environments/dev
terraform init
terraform plan
terraform apply
```

### 3. Triển Khai Tự Động (CI/CD)
Mọi thay đổi khi Push lên `main` hoặc tạo Pull Request sẽ tự động kích hoạt **GitHub Actions**.
> [!IMPORTANT]
> Hãy đảm bảo đã cấu hình `AWS_ACCESS_KEY_ID` và `AWS_SECRET_ACCESS_KEY` trong GitHub Secrets.

---

## 📖 Tài Liệu Chi Tiết (Documentation)

> [!TIP]
> Hãy đọc các tài liệu dưới đây để nắm vững quy trình vận hành dự án.

*   📘 [Kiến Trúc Hạ Tầng](infrastructure/docs/ARCHITECTURE_GUIDE.md) - Sơ đồ và luồng dữ liệu.
*   🤖 [Hướng Dẫn CI/CD](infrastructure/docs/GITHUB_ACTIONS_CICD.md) - Cách vận hành pipeline tự động.
*   🚢 [Quy Trình Triển Khai](infrastructure/docs/DEPLOYMENT_GUIDE.md) - Từng bước đưa app lên cloud.
*   🛠️ [Xử Lý Lỗi](infrastructure/docs/TROUBLESHOOTING.md) - Giải pháp cho các vấn đề thường gặp.
*   📐 [Sử Dụng Templates](infrastructure/templates/README_BOILERPLATE.md) - Cách mở rộng dự án.

---

## 🤝 Hỗ Trợ & Đóng Góp
