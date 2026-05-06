# 🛠️ Hướng Dẫn Xử Lý Sự Cố (Troubleshooting)

> **Mục tiêu:** Giải quyết nhanh các vấn đề thường gặp khi vận hành Terraform và hạ tầng AWS.

---

## 📌 1. Lỗi Khởi Tạo (Initialization)

### Lỗi: `Backend initialization required`
- **Nguyên nhân:** Bạn vừa thay đổi cấu hình S3 Backend hoặc DynamoDB Lock Table.
- **Giải pháp:** Chạy `terraform init -reconfigure` để đồng bộ lại trạng thái.

### Lỗi: `Error downloading modules`
- **Nguyên nhân:** Kết nối mạng không ổn định hoặc sai địa chỉ `source` trong module.
- **Giải pháp:** Kiểm tra đường truyền và thử chạy lại `terraform init`.

---

## 🔐 2. Lỗi Quyền Truy Cập (IAM & Access)

### Lỗi: `AccessDenied: User is not authorized to perform...`
- **Nguyên nhân:** IAM User/Role của bạn thiếu quyền thực thi API trên AWS.
- **Giải pháp:** 
    - Kiểm tra profile hiện tại: `aws configure list`.
    - Đảm bảo User có đính kèm policy `AdministratorAccess` (hoặc các quyền tối thiểu cho VPC, ECS, RDS).

---

## 🔒 3. Lỗi Trạng Thái (State Lock)

### Lỗi: `Error acquiring the state lock`
- **Nguyên nhân:** Một phiên `apply` trước đó bị ngắt quãng hoặc có người khác đang chạy lệnh.
- **Giải pháp:**
    - Nếu chắc chắn không có ai đang deploy, copy `Lock Info ID` từ thông báo lỗi.
    - Chạy: `terraform force-unlock <LOCK_ID>`.

---

## 🔄 4. Lỗi Phụ Thuộc (Dependency)

### Lỗi: `DependencyViolation: The vpc has dependencies`
- **Nguyên nhân:** Bạn đang chạy `destroy` nhưng vẫn còn các tài nguyên tạo thủ công (không qua Terraform) đang nằm trong VPC đó.
- **Giải pháp:** Vào AWS Console, tìm và xóa các Network Interface (ENI), Security Group hoặc Load Balancer tạo tay trước khi chạy lại lệnh xóa.

---

## 🧩 5. Lỗi Logic (HCL Code)

### Lỗi: `Cycle detected` (Vòng lặp)
- **Nguyên nhân:** Module A cần biến từ Module B, nhưng Module B lại đang chờ dữ liệu từ Module A.
- **Giải pháp:** Kiểm tra lại sơ đồ phụ thuộc. Đảm bảo luồng dữ liệu đi một chiều: **Network -> Application -> Database**.

---

## 💡 Mẹo Chuyên Nghiệp
- **Debug sâu:** Chạy `export TF_LOG=DEBUG` để xem chi tiết từng bước Terraform gọi API AWS.
- **Kiểm tra cú pháp:** Luôn chạy `terraform validate` trước khi `plan`.
- **Dọn dẹp:** Nếu code bị loạn, hãy xóa thư mục ẩn `.terraform` và chạy `init` lại từ đầu.

---
*Tài liệu hỗ trợ dự án Kicks-Shoes.*
