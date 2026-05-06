Dựa trên tài liệu hướng dẫn chi tiết bạn cung cấp, dưới đây là phiên bản Checklist Từng Bước để Setup, Cấu Hình và Deploy dự án Kicks-Shoes-AWS lên AWS, tập trung vào môi trường dev-ai.Checklist Triển Khai Hạ Tầng Terraform (Môi Trường Dev-AI)I. Chuẩn Bị Môi Trường và Điều Kiện Tiên Quyết
Công cụ: Đảm bảo đã cài đặt Terraform (phiên bản vẽ >= 1.5) và AWS CLI.
AWS CLI: Đã login đúng profile.
State Backend: Có quyền truy cập vào S3 backend state bucket kicks-shoes-dev.
Container Image: Chuẩn bị sẵn một container image hợp lệ (Docker URI) để truyền vào biến container_image.
AWS Secrets Manager: Đảm bảo Secret kicks-shoes-dev/app-config đã tồn tại và chứa các key bắt buộc:
JWT_SECRET
JWT_REFRESH_SECRET
MONGODB_URI
GOOGLE_AI_API_KEY, v.v....
Remote State Dependency: Đảm bảo network stack đã được deploy trước (01-network) để app stack (dev-ai) có thể đọc remote state cần thiết.
II. Quy Trình Deploy Hạ Tầng Ứng Dụng (App Stack)
Bước
Mô tả
Lệnh Mẫu
Ghi chú
1. Khởi tạo
Di chuyển đến thư mục dev-ai và chạy init để tải providers, modules và cấu hình S3 backend state.
cd infra/terraform/environments/dev-ai 

 terraform init
Backend S3: kicks-shoes-dev
2. Validate
Kiểm tra cú pháp HCL và format code.
terraform fmt -recursive 

 terraform validate


3. Lập kế hoạch
Chạy plan để xem các thay đổi dự kiến (không tác động đến AWS).
terraform plan \

  -var="container_image=<ECR_URI>"
Luôn chạy plan trước khi apply.
4. Triển khai
Thực thi apply để tạo hoặc cập nhật hạ tầng AWS (bao gồm ALB, ECS Service, DynamoDB, S3, v.v.).
terraform apply \

  -var="container_image=<ECR_URI>"
Cập nhật container_image với URI ECR mới.

Biến quan trọng cần cấu hình: container_image (URI Docker ECR) và enable_custom_domain (mặc định false cho dev).III. Kiểm Tra Sau Khi Deploy (Post-Deploy Verification)
Hành động
Lệnh Mẫu
Mục tiêu kiểm tra
Lấy Outputs
terraform output
Lấy DNS của ALB, tên ECS cluster/service, DynamoDB table, v.v..
Kiểm tra ALB
aws elbv2 describe-load-balancers
Đảm bảo ALB đã được tạo và Target Group đang healthy.
Kiểm tra ECS Service
aws ecs describe-services --cluster <CLUSTER_NAME> --services <SERVICE_NAME>
Xác nhận desired count và running count khớp nhau, service đang stable.
Kiểm tra DynamoDB
aws dynamodb describe-table --table-name <TABLE_NAME>
Xác nhận DynamoDB table cho dữ liệu sản phẩm đã sẵn sàng.
Kiểm tra Health
Truy cập alb_dns_name.
Đảm bảo endpoint GET /api/health trả về HTTP 200 ổn định.

IV. Quy Trình Cập Nhật Ứng Dụng (Khi Code Backend Thay Đổi)

Khi có thay đổi ở backend code, bạn không cần chạy lại toàn bộ Terraform, chỉ cần cập nhật container_image.
Build Docker Image mới: Build và tag image với version mới (ví dụ: <TAG>).
docker build -t kicks-shoes-backend:<TAG> ./backend
Push lên ECR: Đẩy image mới lên ECR repository.
docker push <ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:<TAG>
Áp dụng lại Terraform: Chạy terraform apply để cập nhật Task Definition với image URI mới.
terraform apply -var="container_image=<ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:<TAG>"
(ECS Service sẽ tự động thực hiện force new deployment và rollout phiên bản mới).
V. Xử Lý Lỗi Thường Gặp
Vấn đề
Nguyên nhân thường gặp
Giải pháp nhanh
Error acquiring the state lock
Khóa từ apply trước còn active.
Chờ 30 phút auto-release, hoặc terraform force-unlock <LOCK_ID> (cẩn thận).
data source not found
Network stack (01-network) chưa được deploy.
Deploy stack 01-network trước.
Invalid image
Container image URI sai hoặc chưa push đúng ECR.
Verify ECR image exist và tag chính xác.
Thiếu secret
Secret kicks-shoes-dev/app-config chưa có hoặc thiếu key.
Tạo/cập nhật secret trong AWS Secrets Manager.
Apply thất bại
terraform plan khác giữa local và CI/CD.
Pin version Terraform trong .github/workflows.


