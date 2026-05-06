# 🌐 Hướng Dẫn Sử Dụng Terraform Registry

> **Khái niệm:** [Terraform Registry](https://registry.terraform.io/) là kho lưu trữ trung tâm cho các Providers và Modules được phát triển bởi HashiCorp, các đối tác đám mây (AWS, Azure, GCP) và cộng đồng.

---

## 🔎 1. Tìm Kiếm Module Chất Lượng
Khi tìm kiếm trên Registry, hãy ưu tiên các Module:
- Có nhãn **Verified** (Dấu tích xanh).
- Do các tổ chức uy tín xây dựng (Ví dụ: `terraform-aws-modules`).
- Có số lượng download lớn và tài liệu hướng dẫn (README) chi tiết.

---

## 📦 2. Cách Nhúng Module Vào Dự Án

Ví dụ cách nhúng module VPC chuyên nghiệp để thay thế cho việc tự viết code:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # BẮT BUỘC: Luôn chốt phiên bản để tránh lỗi khi module cập nhật

  name = "kicks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Tiết kiệm chi phí cho môi trường Dev
}
```

---

## 🛠️ 3. Quy Trình Sử Dụng
1. **Khai báo:** Thêm block `module` vào file `.tf`.
2. **Khởi tạo:** Chạy `terraform init`. Terraform sẽ tải code từ Registry về thư mục ẩn `.terraform/modules`.
3. **Sử dụng Output:** Lấy dữ liệu từ module bằng cú pháp: `module.<TÊN_MODULE>.<TÊN_OUTPUT>`.
   - *Ví dụ:* `module.vpc.vpc_id`

---

## 🔄 4. Import Tài Nguyên Có Sẵn
Nếu bạn đã tạo tài nguyên thủ công trên AWS Console và muốn đưa nó vào quản lý bởi Module từ Registry:

```bash
# Cú pháp: terraform import <địa_chỉ_trong_code> <ID_trên_AWS>
terraform import module.vpc.aws_vpc.this vpc-0a1b2c3d4e5f
```

> [!NOTE]
> Việc import vào Module thường phức tạp hơn Resource đơn lẻ. Hãy xem phần "Import" trong tài liệu của từng Module trên Registry để biết chính xác ID cần dùng.

---

## ✨ 5. Tại Sao Nên Dùng Registry Modules?
- **Best Practices:** Được thiết kế dựa trên các tiêu chuẩn bảo mật và hiệu năng cao nhất của AWS.
- **Tiết kiệm thời gian:** Giảm 80% lượng code cần viết.
- **Cộng đồng hỗ trợ:** Lỗi thường được phát hiện và sửa chữa cực nhanh bởi hàng ngàn dev khác.

---
*Mẹo: Luôn kiểm tra tab "Inputs" và "Outputs" trên Registry để biết các thông số cấu hình cần thiết.*
