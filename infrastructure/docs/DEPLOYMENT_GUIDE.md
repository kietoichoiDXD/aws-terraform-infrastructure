# Hướng Dẫn Thiết Lập Và Triển Khai Hạ Tầng (Deployment Guide)

Tài liệu này hướng dẫn chi tiết cách chuẩn bị môi trường và các bước để triển khai bộ code Terraform chuyên nghiệp này lên AWS.

## 1. Chuẩn Bị Môi Trường (Prerequisites)

Trước khi bắt đầu, bạn cần cài đặt các công cụ sau:

1.  **Terraform CLI**: [Tải về tại đây](https://developer.hashicorp.com/terraform/downloads). Đảm bảo phiên bản `>= 1.5.0`.
2.  **AWS CLI**: [Tải về tại đây](https://aws.amazon.com/cli/). Sau khi cài xong, chạy lệnh `aws configure` để thiết lập Access Key và Secret Key.
3.  **Tài khoản AWS**: Quyền truy cập IAM User với policy `AdministratorAccess` để tránh lỗi thiếu quyền.

## 2. Cấu Trúc Dự Án (Project Structure)

Bộ code này sử dụng mô hình **Module + Environment**:
*   `modules/`: Chứa code logic chung (không thay đổi giữa các môi trường).
*   `environments/dev/`: Chứa các giá trị cấu hình cụ thể cho môi trường Dev (vùng AWS, dải IP, tên dự án).

## 3. Quy Trình Thiết Lập Code (Configuration)

### Bước 1: Cấu hình biến môi trường
Mở file `infrastructure/environments/dev/terraform.tfvars` và cập nhật các thông số sau cho phù hợp với bạn:
*   `aws_region`: Vùng bạn muốn triển khai (ví dụ: `ap-southeast-1` cho Singapore).
*   `project_name`: Tên dự án của bạn (ví dụ: `my-cool-app`).
*   `vpc_cidr`: Dải IP mạng (mặc định `10.0.0.0/16`).
*   `container_image`: URI của image Docker (mặc định `nginx:latest` cho dev).
*   `container_port`: Cổng ứng dụng (mặc định `80`).

### Bước 2: Cấu hình Provider
Mở file `infrastructure/environments/dev/providers.tf`:
*   Nếu bạn sử dụng profile AWS cụ thể, hãy khai báo `profile = "tên-profile"`.
*   Nếu làm việc nhóm, hãy cấu hình `backend "s3"` để lưu trữ state file tập trung.

## 4. Các Bước Triển Khai (Execution)

Chạy các lệnh sau tại thư mục `infrastructure/environments/dev`:

```bash
# 1. Khởi tạo - Tải provider và module
terraform init

# 2. Định dạng code - Giúp code sạch sẽ, chuẩn hóa
terraform fmt -recursive ../../

# 3. Kiểm tra tính hợp lệ - Bắt lỗi cú pháp trước khi chạy
terraform validate

# 4. Lập kế hoạch - Xem trước các tài nguyên sẽ được tạo
terraform plan

# 5. Triển khai - Gõ 'yes' khi được hỏi để xác nhận
terraform apply
```

## 5. Kiểm Tra Sau Triển Khai

Sau khi lệnh `apply` thành công, Terraform sẽ hiển thị các **Outputs**. Bạn có thể dùng các thông tin này để:
*   Kiểm tra VPC trên AWS Console.
*   Lấy tên bảng DynamoDB để cấu hình cho Backend.
*   Lấy tên S3 Bucket để upload file.

## 6. Dọn Dẹp Tài Nguyên

Để tránh phát sinh chi phí khi không sử dụng, hãy chạy:
```bash
terraform destroy
```

---
**Lưu ý**: Luôn kiểm tra file `TROUBLESHOOTING.md` nếu gặp bất kỳ lỗi nào trong quá trình thực hiện!
