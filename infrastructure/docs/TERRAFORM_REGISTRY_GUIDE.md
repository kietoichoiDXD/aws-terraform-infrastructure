# Hướng Dẫn Sử Dụng Terraform Registry

[Terraform Registry](https://registry.terraform.io/) là một thư viện khổng lồ chứa các Provider và Module được cộng đồng và các hãng công nghệ lớn (AWS, Google, HashiCorp...) xây dựng sẵn. Việc sử dụng Registry giúp bạn giảm thiểu lượng code phải viết và đảm bảo hạ tầng tuân theo các "Best Practices".

---

## 1. Cách Tìm Kiếm Module
Bạn truy cập vào [registry.terraform.io](https://registry.terraform.io/), chọn **Modules** và tìm kiếm theo từ khóa (ví dụ: `vpc`, `eks`, `alb`).
*   Nên ưu tiên các module có nhãn **"Verified"** (có dấu tích xanh) từ các tổ chức uy tín như `terraform-aws-modules`.

## 2. Cách Sử Dụng Module Từ Registry

Để sử dụng một module, bạn chỉ cần khai báo block `module` trong code của mình với tham số `source`.

### Ví dụ: Sử dụng module VPC "xịn" nhất của AWS
Thay vì tự viết hàng trăm dòng code VPC, bạn có thể dùng module `terraform-aws-modules/vpc/aws`:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # Cực kỳ quan trọng: Luôn luôn chốt phiên bản (pin version)

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Tiết kiệm chi phí cho môi trường Dev

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

## 3. Các Bước Để Module Hoạt Động

1.  **Khai báo**: Viết block `module` như ví dụ trên vào file `.tf` của bạn.
2.  **Khởi tạo (Init)**: Chạy lệnh sau để Terraform tải code của module từ Registry về máy local:
    ```bash
    terraform init
    ```
    *Terraform sẽ tạo thư mục ẩn `.terraform/modules` để lưu trữ code này.*
3.  **Sử dụng Output**: Để lấy giá trị từ module registry (ví dụ lấy VPC ID), bạn dùng cú pháp:
    `module.vpc.vpc_id`

## 4. Tại Sao Nên Dùng Registry Module?

*   **Độ tin cậy cao**: Được hàng ngàn kỹ sư sử dụng và đóng góp ý kiến.
*   **Tiêu chuẩn bảo mật**: Thường tích hợp sẵn các cấu hình bảo mật tối ưu.
*   **Tiết kiệm thời gian**: Bạn chỉ cần cung cấp các biến (inputs), module sẽ lo phần logic phức tạp bên dưới.
*   **Cập nhật dễ dàng**: Khi có phiên bản mới, bạn chỉ cần đổi số `version` và chạy lại `terraform init -upgrade`.

---

## 5. Lưu Ý Về Việc Nhập (Import) Tài Nguyên Cũ

Nếu bạn đã có tài nguyên tạo bằng tay trên Console và muốn đưa nó vào quản lý bởi một Module từ Registry, bạn cần dùng lệnh `terraform import`:

```bash
# Cấu trúc: terraform import <địa_chỉ_resource_trong_code> <ID_thực_tế_trên_AWS>
terraform import module.vpc.aws_vpc.this vpc-0a1b2c3d4e5f
```
*(Lưu ý: Việc import vào module phức tạp hơn import vào resource thông thường, hãy đọc kỹ tài liệu của module đó trên Registry).*

---
**Mẹo**: Luôn đọc phần **"Inputs"** và **"Outputs"** trên trang Registry của module đó để biết cách truyền dữ liệu và lấy kết quả trả về!
