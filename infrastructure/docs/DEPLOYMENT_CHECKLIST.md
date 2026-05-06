# ✅ Checklist Triển Khai Hạ Tầng (Kicks-Shoes)

> **Mục tiêu:** Đảm bảo quá trình triển khai diễn ra mượt mà, không thiếu sót các bước quan trọng về bảo mật và vận hành.

---

## 🏗️ I. Điều Kiện Tiên Quyết (Prerequisites)
- [ ] **Terraform:** Đã cài đặt phiên bản `>= 1.5.0`.
- [ ] **AWS CLI:** Đã cấu hình profile với quyền `AdministratorAccess` (hoặc tương đương).
- [ ] **S3 Backend:** Đảm bảo Bucket lưu State đã tồn tại (hoặc chạy stack khởi tạo trước).
- [ ] **Secrets Manager:** Đã tạo secret `kicks-shoes/app-config` với đầy đủ các key (`JWT_SECRET`, `MONGODB_URI`, v.v.).

---

## 🚀 II. Quy Trình Triển Khai (Deployment Steps)

### 1. Khởi tạo & Kiểm tra
- [ ] Chạy `terraform init` để tải providers và modules.
- [ ] Chạy `terraform fmt -recursive` để dọn dẹp code.
- [ ] Chạy `terraform validate` để kiểm tra lỗi cú pháp.

### 2. Lập kế hoạch (Planning)
- [ ] Chạy `terraform plan -var-file="terraform.tfvars" -out=tfplan`.
- [ ] Review lại `tfplan`:
    - [ ] Các tài nguyên bị xóa (`destroy`) có nằm trong dự tính không?
    - [ ] Các tài nguyên mới (`create`) đã đúng cấu hình chưa?

### 3. Thực thi (Applying)
- [ ] Chạy `terraform apply tfplan`.
- [ ] Đợi quá trình hoàn tất (thường mất 5-10 phút cho toàn bộ stack).

---

## 🧪 III. Kiểm Tra Sau Khi Deploy (Post-Deployment)
- [ ] **ALB DNS:** Lấy URL từ output và truy cập thử.
- [ ] **Health Check:** Kiểm tra endpoint `/api/health` trả về `200 OK`.
- [ ] **ECS Service:** Đảm bảo số lượng `Running Tasks` bằng với `Desired Tasks`.
- [ ] **Database:** Kiểm tra quyền truy cập từ ECS vào RDS/DynamoDB (Sử dụng CloudWatch Logs).

---

## 🆘 IV. Xử Lý Sự Cố Nhanh
- [ ] **Lỗi 502/504:** Kiểm tra Security Group của ALB và ECS Service.
- [ ] **Task Stopped:** Xem `Stopped Reason` trong ECS Console (Thường do thiếu biến môi trường hoặc lỗi code app).
- [ ] **State Lock:** Chạy `terraform force-unlock <LOCK_ID>` nếu chắc chắn không có ai đang apply.

---
> [!IMPORTANT]
> Luôn giữ file `tfplan` an toàn trong quá trình deploy để đảm bảo những gì bạn thấy ở bước Plan là những gì sẽ được thực thi ở bước Apply.
