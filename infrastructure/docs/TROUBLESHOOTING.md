# Hướng Dẫn Xử Lý Lỗi (Troubleshooting) - Terraform on AWS

Tài liệu này liệt kê các lỗi phổ biến khi triển khai hạ tầng bằng Terraform lên AWS và cách khắc phục chuyên nghiệp.

## 1. Lỗi Init & Backend

### Lỗi: `Error: Failed to get existing workspaces` hoặc `Error: Backend initialization required`
*   **Nguyên nhân**: Bạn đã thay đổi cấu hình backend (ví dụ: đổi tên bucket S3 lưu state) hoặc chưa chạy `init`.
*   **Cách sửa**: Chạy `terraform init -reconfigure`. Lệnh này sẽ yêu cầu Terraform cấu hình lại backend và copy state cũ sang backend mới nếu cần.

## 2. Lỗi Quyền Truy Cập (Permissions)

### Lỗi: `Error: describing Elastic IP addresses: UnauthorizedOperation`
*   **Nguyên nhân**: IAM User/Role bạn đang dùng không có đủ quyền thực hiện các API call của AWS.
*   **Cách sửa**:
    *   Kiểm tra `aws configure list` để xem đang dùng profile nào.
    *   Đảm bảo IAM User có quyền `AdministratorAccess` (cho môi trường Lab) hoặc các policy cụ thể (VPCFullAccess, DynamoDBFullAccess, S3FullAccess).

## 3. Lỗi Tài Nguyên Đã Tồn Tại (Resource Conflict)

### Lỗi: `Error: creating CloudFront Distribution: CNAMEAlreadyExists` hoặc `BucketAlreadyExists`
*   **Nguyên nhân**: Bạn đang cố gắng tạo một tài nguyên mà tên (hoặc CNAME) của nó đã bị chiếm dụng bởi một tài khoản AWS khác trên toàn thế giới (đối với S3/CloudFront).
*   **Cách sửa**: Đổi tên bucket hoặc thêm một chuỗi ngẫu nhiên (dùng resource `random_id`) vào hậu tố của tên tài nguyên.

## 4. Lỗi Trạng Thái (State Lock)

### Lỗi: `Error: Error acquiring the state lock`
*   **Nguyên nhân**: Một người khác đang chạy `terraform apply` hoặc lệnh trước đó bị crash giữa chừng khiến DynamoDB lock không được giải phóng.
*   **Cách sửa**:
    *   Kiểm tra xem có ai đang deploy không.
    *   Nếu chắc chắn không có ai, lấy `Lock Info ID` từ thông báo lỗi và chạy: `terraform force-unlock <LOCK_ID>`.

## 5. Lỗi Dependency (Phụ thuộc)

### Lỗi: `Error: deleting Subnet: DependencyViolation`
*   **Nguyên nhân**: Bạn đang xóa Subnet nhưng vẫn còn Network Interface (ENI) hoặc EC2 Instance đang chạy trong đó.
*   **Cách sửa**: Kiểm tra và xóa các tài nguyên phụ thuộc trước (thường là do tạo bằng tay trên Console mà không qua Terraform).

## 6. Lỗi Cấu Hình (Configuration)

### Lỗi: `Error: cycle: module.network.var.vpc_id (expand)`
*   **Nguyên nhân**: Lỗi vòng lặp (Circular Dependency). A cần B, B lại cần A.
*   **Cách sửa**: Kiểm tra lại logic truyền biến giữa các module trong `main.tf`. Đảm bảo luồng dữ liệu đi một chiều (ví dụ: Network -> App -> Database).

---
**Mẹo chuyên nghiệp**: Luôn chạy `terraform fmt` để format code đẹp và `terraform validate` trước khi `plan` để bắt lỗi cú pháp sớm!
