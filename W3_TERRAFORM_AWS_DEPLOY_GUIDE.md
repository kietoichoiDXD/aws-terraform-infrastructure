# Kicks-Shoes-AWS W3 Master Document

Tài liệu này là **một file duy nhất** để nắm toàn bộ Week 3 của project `Kicks-Shoes-AWS`. Nó gộp luôn:

- kiến trúc tổng quan
- Terraform setup và backend state
- cấu hình AWS cần thiết
- deploy lên AWS
- upload image lên ECR
- query DynamoDB
- Bedrock / Lambda / ECS / ALB
- Evidence Pack cần nộp
- checklist và troubleshooting

Mục tiêu là chỉ cần mở file này là có thể đi từ đầu đến cuối mà không cần đọc thêm file khác.

---

## 1. Mục Tiêu W3

Week 3 tập trung vào 4 khối chính:

1. **Database Layer**: dùng DynamoDB làm key-value database, private, encrypted, HA-enabled.
2. **AI Layer**: Bedrock Knowledge Base + retrieval flow cho chatbot.
3. **Lambda Layer**: scoped IAM, không wildcard, Lambda làm glue giữa UI, Bedrock và DynamoDB.
4. **VPC & Networking**: 3-tier architecture, S3/DynamoDB Gateway Endpoints, security group references bằng SG ID.

Kết quả cuối cùng phải có:

- hạ tầng AWS deploy được bằng Terraform
- app chạy được qua ALB / ECS / Lambda
- query DynamoDB theo PK và GSI hoạt động
- Bedrock retrieval trả kết quả thật
- Evidence Pack đủ 7 section

---

## 2. Deliverables Cần Có

### Core files

- `docs/W3_evidence.md`
- `docs/ARCHITECTURE.md`
- `infra/terraform/environments/dev-ai/*`
- `backend/lambda/bedrock_retriever/lambda_function.py`
- `backend/lambda/product_ingester/lambda_function.py`
- `frontend/src/components/ChatBot.jsx`
- `frontend/src/components/ChatBot.css`
- `scripts/ingest_products.py`

### Reference files

- `W3_CONTEXT.md`
- `W3_QUICK_REFERENCE.md`
- `W3_IMPLEMENTATION_ROADMAP.md`
- `W3_SUBMISSION_SUMMARY.md`

Nếu chỉ muốn một tài liệu đọc nhanh, thì file này là đủ.

---

## 3. Cấu Trúc Repo Liên Quan

Các phần liên quan nhất trong repo hiện tại:

- `infra/terraform/modules/network`
- `infra/terraform/modules/dynamodb`
- `infra/terraform/environments/dev-ai`
- `backend/lambda/bedrock_retriever`
- `backend/lambda/product_ingester`
- `frontend/src`
- `scripts/ingest_products.py`
- `docs/W3_evidence.md`

Điểm quan trọng: environment deploy chính cho W3 là `infra/terraform/environments/dev-ai`.

---

## 4. Kiến Trúc Tổng Quan

### 4.1 Luồng tổng thể

```text
User
  ↓
React Chatbot UI
  ↓
API / Lambda
  ↓
Bedrock Knowledge Base + DynamoDB
  ↓
ECS / ALB / CloudWatch / Secrets Manager
  ↓
AWS Private Network
```

### 4.2 Các thành phần chính

- **VPC**: chứa public subnet, private app subnet, private database subnet.
- **ALB**: nhận traffic public và forward vào ECS.
- **ECS Fargate**: chạy backend trong private subnet.
- **DynamoDB**: lưu product data, query theo `pk`/`sk` và GSI.
- **S3**: upload assets và lưu docs cho Bedrock KB.
- **Bedrock Knowledge Base**: retrieval layer cho chatbot.
- **Lambda**: xử lý query đến Bedrock / DynamoDB theo IAM scope.
- **CloudWatch Logs**: log ECS / Lambda.
- **Secrets Manager**: giữ secret runtime.
- **Cognito**: auth layer cho frontend.

---

## 5. Terraform Setup

### 5.1 Environment chính

Environment `dev-ai` là nơi ghép toàn bộ stack lại:

- `versions.tf`: backend state S3
- `providers.tf`: AWS provider
- `data.tf`: remote state + secrets + caller identity
- `variables.tf`: input biến
- `main.tf`: network, ECS, ALB, DynamoDB, S3, Cognito, Bedrock, Lambda
- `outputs.tf`: output sau deploy

### 5.2 Backend S3

File `infra/terraform/environments/dev-ai/versions.tf` dùng backend S3:

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "kicks-shoes-dev"
    key     = "dev-ai/app/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
```

Ý nghĩa:

- `bucket`: nơi lưu state
- `key`: state path riêng cho app stack
- `region`: region của state bucket
- `encrypt`: bật mã hóa state

### 5.3 AWS Provider

File `providers.tf` cấu hình:

- provider chính theo `var.aws_region`
- alias provider `us_east_1` khi cần ACM / CloudFront / WAF

### 5.4 Remote State

File `data.tf` đọc:

- remote state của network stack
- secret từ Secrets Manager
- account identity hiện tại

Ví dụ remote state network:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "kicks-shoes-dev"
    key    = "dev/network/terraform.tfstate"
    region = "us-west-2"
  }
}
```

---

## 6. Biến Quan Trọng

File `variables.tf` cho `dev-ai` có các biến quan trọng nhất:

- `project_name`
- `aws_region`
- `domain_name`
- `enable_custom_domain`
- `container_image`
- `container_port`
- `desired_count`
- `task_cpu`
- `task_memory`
- `autoscaling_min`
- `autoscaling_max`
- `autoscaling_cpu_target`
- `app_config_secret_name`
- `tags`

### 6.1 Giá trị mặc định đáng chú ý

- `aws_region = us-west-2`
- `container_port = 3000`
- `desired_count = 1`
- `task_cpu = 256`
- `task_memory = 512`
- `autoscaling_min = 1`
- `autoscaling_max = 3`
- `autoscaling_cpu_target = 60`
- `app_config_secret_name = kicks-shoes-dev/app-config`

### 6.2 Ví dụ chạy plan

```bash
terraform plan \
  -var="aws_region=us-west-2" \
  -var="container_image=<ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:latest" \
  -var="enable_custom_domain=false"
```

---

## 7. Chuẩn Bị AWS Trước Khi Deploy

Bạn cần:

- AWS CLI login đúng profile
- Terraform >= 1.5
- S3 backend state bucket tồn tại
- ECR repository đã có hoặc sẵn sàng push image
- Secret trong Secrets Manager với name `kicks-shoes-dev/app-config`

### 7.1 Secret cần có các key

- `JWT_SECRET`
- `JWT_REFRESH_SECRET`
- `MONGODB_URI`
- `GOOGLE_AI_API_KEY`
- `GOOGLE_MAILER_CLIENT_ID`
- `GOOGLE_MAILER_CLIENT_SECRET`
- `GOOGLE_MAILER_REFRESH_TOKEN`

### 7.2 Nếu bật custom domain

Cần thêm:

- `domain_name`
- `enable_custom_domain=true`
- hosted zone Route 53 tương ứng

---

## 8. Terraform Sẽ Tạo Ra Những Gì

Từ `infra/terraform/environments/dev-ai/main.tf`, stack này tạo:

- Security Group cho ALB, ECS, Redis
- ALB public
- ECS Fargate service chạy trong private subnet
- CloudWatch log group cho ECS
- DynamoDB table cho products
- S3 bucket cho uploads
- S3 bucket cho Bedrock KB
- ElastiCache Redis trong private subnet
- Cognito User Pool và User Pool Client
- CloudFront distribution nếu bật domain
- WAF cho CloudFront nếu bật domain
- Route53 records nếu bật domain
- IAM role/policy cho ECS task và Lambda
- Bedrock Knowledge Base
- S3 data source cho Bedrock
- Lambda `bedrock_retriever`

### 8.1 Điều quan trọng về network

- ECS task chạy trong private subnet.
- ECS task không hardcode secret.
- ECS task lấy secret từ Secrets Manager.
- DynamoDB được truy cập theo thiết kế private.

---

## 9. Quy Trình Deploy Hạ Tầng Lên AWS

### 9.1 Thứ tự chuẩn

1. Deploy network stack trước.
2. Deploy app stack `dev-ai`.
3. Push image backend lên ECR.
4. Cập nhật biến `container_image`.
5. Chạy `terraform plan`.
6. Chạy `terraform apply`.
7. Kiểm tra output và test endpoint.

### 9.2 Lệnh chuẩn

```bash
cd infra/terraform/environments/dev-ai

terraform init
terraform fmt -recursive
terraform validate

terraform plan \
  -var="container_image=<ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:latest"

terraform apply \
  -var="container_image=<ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:latest"
```

### 9.3 Nếu chỉ đổi code backend

Quy trình đúng là:

1. Build image mới.
2. Push lên ECR.
3. Cập nhật `container_image`.
4. Apply lại Terraform để ECS rollout.

Ví dụ:

```bash
docker build -t kicks-shoes-backend:<TAG> ./backend
docker tag kicks-shoes-backend:<TAG> <ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:<TAG>
docker push <ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:<TAG>

cd infra/terraform/environments/dev-ai
terraform apply -var="container_image=<ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:<TAG>"
```

---

## 10. Thành Phần AWS Chính

### 10.1 VPC & Security Groups

Terraform module `network` tạo:

- public subnet
- private subnet
- NAT Gateway
- route tables
- associations

Trong `dev-ai/main.tf`, các security group chính gồm:

- `sg_alb`: cho ALB
- `sg_ecs`: cho ECS, chỉ nhận traffic từ ALB SG
- `sg_redis`: cho Redis, chỉ nhận traffic từ ECS SG

Điểm quan trọng: security group reference bằng ID, không mở bằng CIDR không cần thiết.

### 10.2 DynamoDB

Module `dynamodb` tạo table với:

- billing mode on-demand
- hash key `pk`
- range key `sk`
- PITR enabled

Mục tiêu là phục vụ truy vấn key-value nhanh, latency thấp, phù hợp pattern của W3.

### 10.3 S3 Uploads Bucket

Bucket upload có:

- block public access
- server-side encryption
- force destroy cho lab
- lifecycle rule cleanup file tạm

### 10.4 ECS Service

ECS service chạy:

- launch type: Fargate
- subnet private
- SG riêng
- autoscaling theo CPU
- health check qua ALB
- log driver `awslogs`

### 10.5 Lambda Bedrock Retriever

Lambda có mục tiêu:

- gọi Bedrock retrieval
- query DynamoDB
- trả JSON response cho API hoặc flow khác

IAM role của Lambda phải scoped, không wildcard.

### 10.6 Bedrock Knowledge Base

Bedrock KB kết nối:

- S3 bucket docs
- OpenSearch Serverless
- embedding model Amazon Titan

Mục tiêu là retrieval tốt cho chatbot sản phẩm.

---

## 11. Cách Upload Ứng Dụng Lên AWS

### 11.1 Build và push image

```bash
docker build -t kicks-shoes-backend:<TAG> ./backend
docker tag kicks-shoes-backend:<TAG> <ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:<TAG>
docker push <ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:<TAG>
```

### 11.2 Apply lại Terraform sau khi có image

```bash
cd infra/terraform/environments/dev-ai
terraform apply -var="container_image=<ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/kicks-shoes-backend:<TAG>"
```

### 11.3 Kiểm tra output

Sau khi apply, kiểm tra:

- `alb_dns_name`
- `ecs_cluster_name`
- `ecs_service_name`
- `dynamodb_table_name`
- `s3_uploads_bucket`
- `bedrock_knowledge_base_id`
- `lambda_function_name`

Lệnh:

```bash
terraform output

aws elbv2 describe-load-balancers
aws ecs describe-services --cluster <CLUSTER_NAME> --services <SERVICE_NAME>
aws dynamodb describe-table --table-name <TABLE_NAME>
aws lambda get-function --function-name <FUNCTION_NAME>
```

---

## 12. Evidence Pack Cho W3

File chính cần nộp là `docs/W3_evidence.md`.

### 12.1 7 section bắt buộc

1. Cover & DB Path
2. Data Access Pattern Log
3. Deployment Evidence
4. Working Query Evidence
5. Lambda + Bedrock Evidence
6. VPC + Networking Evidence
7. Negative Security Test

### 12.2 Nội dung nên có trong từng section

#### Section 1: Cover & DB Path

- team members
- database path đã chọn
- ngày nộp
- ghi rõ W2 legacy items vẫn còn

#### Section 2: Data Access Pattern Log

- 3 access patterns thật từ app
- engine/paradigm phù hợp
- lý do chọn
- wrong-paradigm test

#### Section 3: Deployment Evidence

- screenshot DynamoDB created
- encryption enabled
- VPC endpoints visible
- Lambda deployed
- Bedrock KB synced

#### Section 4: Working Query Evidence

- PK query
- GSI query
- output thật

#### Section 5: Lambda + Bedrock Evidence

- CloudWatch log
- Bedrock API response
- timestamp

#### Section 6: VPC + Networking Evidence

- diagram 3 tiers
- route table endpoint
- SG reference by ID

#### Section 7: Negative Security Test

- unauthorized access attempt
- denied response
- giải thích lý do private

---

## 13. Data Model Và Query Logic

### 13.1 Vì sao dùng DynamoDB

- query theo key nhanh
- latency ổn định
- schema linh hoạt
- scale tốt với traffic cao
- on-demand phù hợp lab và demo

### 13.2 Access patterns nên có

Các pattern thường gặp cho project shoes e-commerce:

- tìm sản phẩm theo brand
- lấy 1 product theo id
- tìm top-rated shoes theo category

### 13.3 Wrong-paradigm test

Nếu dùng RDS cho pattern key-value đơn giản:

- cần connection pooling
- cần index cẩn thận
- dễ tốn chi phí hơn khi scale
- schema rigid hơn

---

## 14. Bedrock / Lambda / Chatbot Flow

### 14.1 Luồng logic

```text
User click button
  ↓
Frontend gửi query
  ↓
Lambda nhận request
  ↓
Gọi Bedrock retrieval
  ↓
Query DynamoDB theo pattern
  ↓
Merge results
  ↓
Trả JSON response
```

### 14.2 Lambda cần gì

- `BEDROCK_KB_ID`
- `BEDROCK_REGION`
- `DYNAMODB_TABLE`
- `DYNAMODB_REGION`

### 14.3 IAM scope

Lambda execution role không được có:

- `Action: "*"`
- `Resource: "*"`

Phải scope theo ARN của resource thật.

---

## 15. Quy Trình Làm Việc Mẫu

### Monday

- deploy Terraform network/app stack
- kiểm tra state backend

### Tuesday

- push backend image lên ECR
- apply Terraform update image

### Wednesday

- test ECS / ALB / Lambda / CloudWatch

### Thursday

- load products into DynamoDB
- test PK và GSI queries
- sync Bedrock docs

### Friday

- chụp screenshot evidence
- hoàn tất W3_evidence.md
- chuẩn bị demo

---

## 16. Lệnh Kiểm Tra Và Debug Nhanh

### 16.1 Terraform

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform output
```

### 16.2 AWS CLI

```bash
aws dynamodb describe-table --table-name kicks_products
aws ecs describe-services --cluster <CLUSTER_NAME> --services <SERVICE_NAME>
aws lambda get-function --function-name <FUNCTION_NAME>
aws logs tail /ecs/<service> --follow
```

### 16.3 Docker image

```bash
docker images
docker ps
```

---

## 17. Lỗi Hay Gặp

- Sai backend S3 bucket hoặc key.
- Không có remote state network.
- Secret chưa tạo trong Secrets Manager.
- Docker image chưa push đúng ECR.
- ECS task không pull được image.
- Bật custom domain nhưng chưa có ACM hoặc Route 53.
- Security group ingress quá mở hoặc quá chặt.

### 17.1 Nếu Terraform lỗi state

Kiểm tra:

- bucket có tồn tại không
- key có đúng không
- region có đúng không
- quyền access bucket có đủ không

### 17.2 Nếu ECS không chạy

Kiểm tra:

- image URI đúng chưa
- log group có log không
- task definition có env vars không
- SG có cho phép ALB vào port container không

### 17.3 Nếu Lambda không gọi được Bedrock

Kiểm tra:

- IAM role có quyền Bedrock chưa
- region có đúng không
- KB id có đúng không
- Lambda có log lỗi gì không

---

## 18. Checklist Cuối Cùng

- [ ] Network stack deployed
- [ ] App stack `dev-ai` deployed
- [ ] Backend image pushed to ECR
- [ ] Terraform apply thành công
- [ ] ALB DNS hoạt động
- [ ] ECS service healthy
- [ ] DynamoDB table có dữ liệu
- [ ] Bedrock KB sync xong
- [ ] Lambda gọi được
- [ ] W3_evidence.md hoàn chỉnh
- [ ] 7 section có screenshot + notes
- [ ] Negative security test pass

---

## 19. Tóm Tắt Một Dòng

`Terraform deploy → ECR image push → ECS rollout → DynamoDB queries → Bedrock retrieval → Evidence Pack`

---

## 20. Ghi Chú Cuối

Tài liệu này được viết để làm **một file markdown duy nhất** cho toàn bộ quy trình W3. Nếu cần, có thể tiếp tục rút gọn thành:

- bản nộp ngắn hơn
- bản checklist 1 trang
- bản hướng dẫn tiếng Việt ngắn cho thuyết trình

Đây là file master duy nhất nên dùng để đọc và triển khai toàn bộ W3. Nó là source of truth cho toàn bộ nội dung W3. Hãy dùng file này làm tài liệu chính và bỏ qua các file rời nếu chỉ cần một bản duy nhất.
