# 📖 Hướng Dẫn Triển Khai Toàn Diện

> **Dành cho:** DevOps và Engineers muốn thiết lập mới hoặc mở rộng hạ tầng cho dự án Kicks-Shoes.

---

## 🛠️ 1. Cài Đặt Công Cụ
Đảm bảo máy của bạn đã sẵn sàng với bộ công cụ sau:
- **Terraform CLI (v1.5+):** [Download](https://developer.hashicorp.com/terraform/downloads)
- **AWS CLI:** [Download](https://aws.amazon.com/cli/)
- **Git:** Để quản lý mã nguồn hạ tầng.

---

## 📐 2. Hiểu Về Cấu Trúc Dự Án
Dự án được thiết kế theo mô hình **Layered Architecture**:
1. **Modules:** Chứa logic hạ tầng thuần túy (VPC, ECS, RDS...).
2. **Environments (Dev/Prod):** Nơi chứa cấu hình thực tế và gọi các Modules.

---

## ⚙️ 3. Các Bước Cấu Hình

### Bước 1: Khai báo biến
Truy cập `infrastructure/environments/dev/terraform.tfvars` và cập nhật:
- `aws_region`: Vùng triển khai (ưu tiên `ap-southeast-1`).
- `project_name`: Tên dự án (Ví dụ: `kicks-shoes-dev`).
- `container_image`: Link Image từ ECR hoặc Docker Hub.

### Bước 2: Cấu hình Backend
Đảm bảo bạn đã cấu hình S3 Bucket và DynamoDB Table để lưu State trong file `versions.tf`.

---

## 🚀 4. Thực Thi Triển Khai

Di chuyển vào thư mục môi trường tương ứng (ví dụ: `environments/dev`):

```bash
# Khởi tạo dự án
terraform init

# Kiểm tra định dạng code
terraform fmt -recursive

# Xác thực cú pháp
terraform validate

# Xem trước thay đổi
terraform plan

# Áp dụng hạ tầng (Gõ 'yes' để xác nhận)
terraform apply
```

---

## 🔍 5. Kiểm Tra Kết Quả
Sau khi `apply` thành công, hãy chú ý đến phần **Outputs** hiển thị trên màn hình:
- **ALB DNS Name:** Link để truy cập ứng dụng.
- **ECS Cluster Name:** Dùng để quản lý các containers.
- **S3 Bucket Name:** Dùng để upload ảnh sản phẩm.

---

## 🧹 6. Dọn Dẹp Tài Nguyên
Khi không còn sử dụng (ví dụ: sau khi test xong môi trường Dev), hãy xóa tài nguyên để tránh mất tiền:
```bash
terraform destroy
```

> [!WARNING]
> Lệnh `destroy` sẽ xóa VĨNH VIỄN toàn bộ hạ tầng và dữ liệu. Hãy cực kỳ cẩn thận khi sử dụng ở môi trường Production.

---
*Tài liệu này là một phần của bộ Boilerplate Terraform Kicks-Shoes.*
