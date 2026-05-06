# Kicks-Shoes AWS Infrastructure - Hệ Thống Hạ Tầng Terraform Chuyên Nghiệp

Chào mừng bạn đến với kho lưu trữ hạ tầng của dự án **Kicks-Shoes**. Tài liệu này giải thích chi tiết về cấu trúc thư mục, chức năng của từng file và cách vận hành hệ thống theo tiêu chuẩn công nghiệp.

---

## 1. Cấu Trúc Tổng Thể (Project Structure)

```text
.
├── infrastructure/               # Thư mục chính chứa toàn bộ code Terraform
│   ├── modules/                  # Các khối tài nguyên có thể tái sử dụng (Building Blocks)
│   │   ├── network/              # Hạ tầng mạng cốt lõi
│   │   ├── load_balancer/        # Bộ cân bằng tải (ALB)
│   │   ├── ecs/                  # Quản lý Container (ECS Fargate)
│   │   ├── iam/                  # Phân quyền và bảo mật
│   │   ├── database/             # Cơ sở dữ liệu (DynamoDB)
│   │   └── storage/              # Lưu trữ tệp tin (S3)
│   ├── environments/             # Cấu hình cụ thể cho từng môi trường triển khai
│   │   └── dev/                  # Môi trường Development (Môi trường hiện tại)
│   └── docs/                     # Hệ thống tài liệu hướng dẫn kỹ thuật
└── README.md                     # File bạn đang đọc
```

---

## 2. Giải Thích Chi Tiết Từng Thành Phần (Detailed File Explanations)

### 📂 Thư mục `modules/` (Building Blocks)
Đây là nơi chứa các khối hạ tầng tái sử dụng. Mỗi module thường có 3 file:
-   **`main.tf`**: Định nghĩa tài nguyên (Resource). Đây là nơi thực sự "xây dựng" hạ tầng trên AWS.
-   **`variables.tf`**: Khai báo các tham số đầu vào (Inputs) để module linh hoạt hơn.
-   **`outputs.tf`**: Trả về các giá trị (Outputs) sau khi tạo xong (VD: ID của một Security Group) để các module khác sử dụng.

**Các module cụ thể:**
1.  **`network/`**: Thiết lập VPC, Subnets (Public/Private), Internet Gateway và NAT Gateway. Đây là "móng nhà" của toàn bộ hệ thống.
2.  **`iam/`**: Tạo các Role và Policy. Quan trọng nhất là `Task Execution Role` để ECS có quyền kéo Image từ ECR và `Task Role` để ứng dụng truy cập DynamoDB.
3.  **`load_balancer/`**: Cấu hình Application Load Balancer (ALB). Đây là "cửa ngõ" đón và điều phối traffic từ người dùng.
4.  **`ecs/`**: Quản lý Cluster và Service chạy Docker. Định nghĩa cách ứng dụng vận hành (CPU, RAM, Logging).
5.  **`database/`**: Cấu hình DynamoDB - Nơi lưu trữ dữ liệu sản phẩm và đơn hàng của Kicks-Shoes.
6.  **`storage/`**: Cấu hình S3 Buckets để lưu trữ hình ảnh sản phẩm và assets tĩnh.

---

### 📂 Thư mục `environments/dev/` (Cấu hình triển khai)
Đây là nơi bạn trực tiếp thao tác lệnh `terraform`.
-   **`main.tf`**: File "tổng lực", đóng vai trò kết nối tất cả các module trên lại với nhau thành một hệ thống hoàn chỉnh.
-   **`providers.tf`**: Cấu hình kết nối với AWS và đặc biệt là **S3 Remote Backend**. Nó giúp lưu trữ trạng thái (State) của hạ tầng lên đám mây, cho phép cả team cùng làm việc mà không bị ghi đè dữ liệu.
-   **`terraform.tfvars`**: **File quan trọng nhất đối với người dùng.** Đây là nơi bạn điền các thông tin thực tế: tên project, link Docker image, dải IP mong muốn...
-   **`variables.tf`**: Khai báo các biến mà môi trường này sẽ nhận từ người dùng.
-   **`outputs.tf`**: Hiển thị kết quả sau khi deploy thành công (VD: Link truy cập website).

---

### 📂 Thư mục `docs/` (Hệ thống tài liệu kỹ thuật)
-   **`ARCHITECTURE_GUIDE.md`**: Giải thích sơ đồ mạng và bảo mật.
-   **`DEPLOYMENT_GUIDE.md`**: Hướng dẫn chi tiết cách cài đặt và chạy lệnh triển khai.
-   **`TERRAFORM_REGISTRY_GUIDE.md`**: Cách tìm kiếm và sử dụng các module cộng đồng từ [Terraform Registry](https://registry.terraform.io/).
-   **`TROUBLESHOOTING.md`**: "Cứu cánh" khi gặp lỗi. Chứa các lỗi phổ biến và cách khắc phục nhanh.

---

## 3. Tại sao cấu trúc này lại "Chuyên nghiệp"? (Best Practices)

1.  **Tính Module hóa (Modularity)**: Dễ dàng thay thế hoặc nâng cấp từng phần (ví dụ đổi từ DynamoDB sang RDS) mà không phá vỡ hệ thống.
2.  **Bảo mật phân tầng (Security Layers)**: Ứng dụng chạy trong Private Subnet (không có internet trực tiếp), bảo vệ tối đa dữ liệu khách hàng.
3.  **Quản lý State an toàn**: Sử dụng S3 + DynamoDB Lock giúp tránh xung đột khi nhiều người cùng deploy.
4.  **Dễ dàng mở rộng (Scalability)**: Muốn thêm môi trường `production`? Chỉ cần copy thư mục `dev` sang `prod` và thay đổi thông số.

---

## 4. Cách sử dụng nhanh (Quick Start)

1.  **Cấu hình**: Chỉnh sửa file `infrastructure/environments/dev/terraform.tfvars` theo ý bạn.
2.  **Khởi tạo**: 
    ```bash
    cd infrastructure/environments/dev
    terraform init
    ```
3.  **Triển khai**:
    ```bash
    terraform plan
    terraform apply
    ```

---
*Dự án Kicks-Shoes - Hạ tầng được thiết kế bởi Antigravity AI.*
