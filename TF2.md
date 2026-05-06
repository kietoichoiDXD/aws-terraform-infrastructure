03-backend — Backend Deploy & Backend Processing Guide
Path: infra/terraform/environments/dev/02-app/ (hạ tầng chạy backend)
App source: backend/src/
Container port: 3000
Health endpoint chuẩn: GET /api/health


1) Mục tiêu tài liệu
Tài liệu này mô tả đầy đủ cho team backend:

Backend chạy ở đâu trong kiến trúc dev Terraform.
Luồng deploy backend từ lúc kiểm tra trước deploy đến khi verify sau deploy.
Các xử lý backend quan trọng cần nắm khi vận hành (health, log, secret, scaling, rollback).
Mẫu cách viết tài liệu backend để ai mới vào dự án cũng đọc và làm theo được.


2) Backend delivery status hiện tại
Mục này dùng để nhìn nhanh tiến độ implementation backend trong bộ Terraform dev.
2.1 Tổng quan
Backend: 75% Complete
Completed: 39/52 components
Network Layer: 100%
Application Layer: 70%
2.2 Network layer đã hoàn tất
VPC
Subnets
NAT Gateway
Route Tables
2.3 Application layer đã hoàn tất
ECS Cluster + Service + Auto Scaling
ALB + Target Group
Security Groups
DynamoDB + ElastiCache Redis
S3 uploads bucket
Cognito User Pool
CloudFront distribution
Secrets Manager
CloudWatch Logs + SNS
2.4 Ý nghĩa của trạng thái này
Network layer đã đủ ổn định để app layer consume qua remote state.
Application layer đã có đầy đủ phần core runtime để backend chạy, scale và quan sát.
Các phần còn lại nên được viết theo cùng chuẩn: rõ input, rõ output, rõ cách verify và rõ rollback.
2.5 Ảnh này đang nói gì
Ảnh trong mô tả backend là một bảng trạng thái tiến độ. Nó không chỉ cho biết % hoàn thành, mà còn cho team biết phần nào đã đủ để deploy, phần nào chỉ là hạ tầng đã xong, và phần nào là application runtime đã sẵn sàng.

Các ý chính trong ảnh:

Tổng tiến độ backend đang ở mức 75%.
Đã hoàn thành 39/52 components.
Network layer đã xong 100%, nên nền tảng mạng không còn là blocker.
Application layer đang ở mức 70%, nghĩa là backend đã có phần lớn các dịch vụ chạy được nhưng vẫn còn một số mảnh cần hoàn thiện hoặc đồng bộ.
Các checkbox xanh trong ảnh biểu thị các hạng mục đã được triển khai hoặc đã sẵn sàng để sử dụng.
2.6 Cách backend được xử lý theo đúng logic trong ảnh
Backend không chạy theo kiểu một khối duy nhất, mà được xử lý theo từng lớp:

Lớp hạ tầng: VPC, subnet, NAT Gateway, route table, security group.
Lớp entry traffic: Route53, CloudFront, ALB, target group.
Lớp compute: ECS Fargate service chạy Node.js backend.
Lớp dữ liệu và trạng thái: DynamoDB, Redis, S3, Secrets Manager.
Lớp quan sát: CloudWatch Logs và SNS.

Khi một request đi vào hệ thống, backend xử lý theo thứ tự:

Request vào Route53 hoặc CloudFront tùy domain.
CloudFront forward API request về ALB.
ALB kiểm tra target group và đẩy request vào ECS task đang healthy.
Express app ở backend/src/app.js nhận request qua middleware.
Request đi qua auth, validation, business logic, repository/service.
Nếu cần dữ liệu thì backend gọi MongoDB, DynamoDB, Redis, S3 hoặc Secrets Manager theo env đang cấu hình.
Response được trả về client và log được gửi về CloudWatch.

Nói ngắn gọn, ảnh này thể hiện backend đã sẵn sàng ở mức kiến trúc: mạng đã xong, app runtime đã có, và phần còn lại là hoàn thiện nốt các module chưa chốt 100%.


3) Backend nằm ở đâu trong kiến trúc
Luồng request (rút gọn):

User -> Route53 -> CloudFront.
CloudFront chuyển API traffic xuống ALB.
ALB forward vào ECS Fargate service (container Node.js Express).
Backend xử lý nghiệp vụ rồi truy cập:
ElastiCache Redis (cache/session nhanh).
DynamoDB (dữ liệu chính theo kiến trúc AWS migration).
S3 bucket upload (ảnh người dùng).
Secrets Manager (inject secret vào runtime env cho container).
CloudWatch thu log và metric để theo dõi vận hành.

Điểm kỹ thuật bắt buộc để service healthy:

App phải bind host 0.0.0.0 trong môi trường production.
PORT của app phải khớp với container port và target group port.
Route GET /api/health phải trả về HTTP 200 ổn định.


4) Thành phần backend runtime (thực tế trong repo)
4.1 Entry point & server
File chính: backend/src/app.js
App khởi tạo:
dotenv, connectDB(), middleware (CORS, helmet, compression, morgan)
route API theo module
cron jobs nội bộ
Socket.IO server
health endpoint

app.js đang có:

GET /api/health trả payload trạng thái runtime.
app.use('/api/health', healthRoutes) cho kiểm tra mở rộng (bao gồm probe DynamoDB).
4.2 Docker backend
Dockerfile runtime chính cho backend: backend/Dockerfile.
Có HEALTHCHECK nội bộ gọi http://localhost:3000/api/health.
Chạy non-root user nodejs.
4.3 Infrastructure deploy bằng Terraform
Network stack: .AIDD/changes/001-dev-terraform-deploy/01-network.md
App stack: .AIDD/changes/001-dev-terraform-deploy/02-app.md
02-app đọc remote state từ 01-network.


5) Luồng deploy backend end-to-end (khuyến nghị)
Stage A — Pre-deploy audit (bắt buộc)
Mục tiêu: bắt lỗi sớm trước khi build/push/deploy.

Script dùng sẵn:

scripts/predeploy-backend-audit.ps1

Những check quan trọng script đang kiểm:

Env bắt buộc: MONGODB_URI, JWT_SECRET, JWT_REFRESH_SECRET, GOOGLE_AI_API_KEY.
Kết nối DB.
Health route có trong source.
Health HTTP check thật khi chạy app local.
Lint strict (0 warning).
Test coverage threshold.
Không để console/debugger rò rỉ trong source production.
Scan pattern hardcoded secrets.
Đồng bộ Docker entrypoint/EXPOSE/WORKDIR với backend.

Lệnh:

./scripts/predeploy-backend-audit.ps1

Chỉ cho phép qua stage tiếp theo khi các mục Critical pass.
Stage B — Build image & push ECR
Script end-to-end sẵn có:

scripts/ecs-fargate-e2e.ps1

Luồng script:

Validate AWS/Docker/Terraform CLI.
Ensure ECR repository tồn tại.
Login ECR.
Pull base image hiện tại.
Build image mới từ source backend.
Push image lên ECR và đọc digest.

Kết quả đầu ra cần ghi vào release note:

Image tag.
Image digest.
Thời điểm deploy UTC.
Stage C — Terraform apply app stack
terraform init
terraform plan
terraform apply

Các biến quan trọng cần đúng:

container_image
container_port
aws_region
name_prefix

Sau apply lấy output:

alb_dns_name
ecs_cluster_name
ecs_service_name
Stage D — ECS rollout
Force new deployment service.
Chờ services-stable.
Verify running/desired count.
Stage E — Post-deploy verify
Checklist chi tiết tham chiếu:

docs/post-deploy-quick-verify-checklist.md

Tối thiểu phải pass:

GET /api/health -> 200.
GET /api/health/dynamodb -> 200, read/write pass.
Frontend gọi API không lỗi CORS/mixed-content.
Route cốt lõi (/api/products, auth flow cơ bản) chạy được.


6) Terraform Deploy & CI/CD Pipeline Integration (chi tiết luồng + state)
6.1 Terraform là gì và tại sao dùng
Terraform là Infrastructure as Code (IaC) tool. Nó cho phép:

Mô tả hạ tầng AWS bằng mã (.tf files) thay vì click button trên console.
Version control hạ tầng cùng với code, track thay đổi, review, merge như code thường.
Tái tạo hạ tầng từ code bất cứ lúc nào, từ lúc không có gì đến đầy đủ trong vài phút.
Reuse module và best practice, tránh duplicated work.

Backend dev dùng Terraform vì:

Network layer (VPC, subnets, NAT) cần dùng chung giữa dev và prod, code reuse.
App layer (ECS, ALB, DynamoDB) cần tạo/xóa nhanh khi test, IaC nhanh hơn click.
Khi merge PR mà hạ tầng thay đổi, Terraform plan giúp review trước khi apply.
6.2 Terraform state: cái gì, ở đâu, sao quan trọng
State file là gì
State file (ví dụ terraform.tfstate) là file JSON chứa:

Trạng thái hiện tại của từng resource AWS (VPC ID, subnet ID, security group ID, ...).
Mapping từ tên resource trong code Terraform sang ID thực tế trong AWS.
Dùng để biết resource nào đã được tạo, cần update, hay cần delete.

Nếu không có state file, Terraform sẽ không biết resource nào do nó tạo, cái gì đã thay đổi.
State lưu ở đâu
Trong dự án Kicks, state lưu ở S3 (backend remote):

Dev network stack: s3://kicks-shoes-tf-state/dev/01-network/terraform.tfstate
Dev app stack: s3://kicks-shoes-tf-state/dev/02-app/terraform.tfstate
Prod network stack: s3://kicks-shoes-tf-state/prod/01-network/terraform.tfstate
Prod app stack: s3://kicks-shoes-tf-state/prod/02-app/terraform.tfstate

Lưu trên S3 thay vì local file vì:

Team có thể chia sẻ state giữa dev machines.
CI/CD pipeline có thể access state để deploy.
Version control state (S3 versioning enabled).
Lockfile (DynamoDB) ngăn 2 người/pipeline không thể apply cùng lúc.
State sensitive information
State file chứa sensitive data (password, secret, key,...), nên:

S3 bucket state phải encrypted (KMS) và access restricted (IAM).
Không commit state vào git.
Chỉ authorized người mới có thể terraform apply.
6.3 CI/CD Pipeline flow
Cách Terraform kết hợp với CI/CD:
Trigger: Khi nào pipeline chạy
Dev push code lên GitHub feature branch.
PR được tạo (nếu backend code hoặc .tf file thay đổi).
GitHub Actions workflow được trigger (bạn xem .github/workflows/deploy.yml).
Stage 1: Validate & Plan (không deploy vào AWS)
Step 1. Checkout code

Step 2. Setup Terraform & AWS credentials

Step 3. terraform init (download modules)

Step 4. terraform validate (check syntax)

Step 5. terraform plan (tính toán thay đổi cần thiết)

  → Plan output được comment vào PR để dev/lead review

  → Bộc lộ các resource sẽ được create/update/delete

Step 6. Security scan (Trivy cho image, tfsec cho Terraform)

Step 7. Lint backend code

Step 8. Run backend tests

Điểm quan trọng: Ở stage này chưa apply gì vào AWS, chỉ check syntactic và output plan để review.
Stage 2: Build & Push image (nếu backend code thay đổi)
Step 1. Build Docker image từ Dockerfile.evolution + backend/src code mới

Step 2. Tag image: kicks-shoes-backend:<git-sha>

Step 3. Push lên ECR (Elastic Container Registry)

  → Image được cache layer, tái dùng khi possible
Stage 3: Apply Terraform (chỉ khi merge vào main/production branch)
Trigger: Push trực tiếp vào kicks-production branch (không phải PR)

Step 1. Checkout code

Step 2. terraform init

Step 3. terraform plan -var container_image=<pushed-image-uri>

  → State được lock (DynamoDB lock)

Step 4. terraform apply <tfplan>

  → Nếu có resource mới, tạo

  → Nếu có thay đổi config, update

  → Nếu resource bị xóa khỏi code, destroy

Step 5. ECS force new deployment

Step 6. ECS wait stable

Step 7. Post-deploy verify

  → CloudWatch health check

  → API endpoint ping

  → If fail → SNS alert / Slack notification

State file tự động update lại S3 sau khi apply thành công.
6.4 Cách Terraform, Code, CI/CD, Deploy kết hợp - Flow từ đầu đến cuối
Giả sử bạn thay đổi backend code và cần thêm một DynamoDB index mới:

1. Local machine: Edit backend/src/service.js (code logic) 

                  + infra/terraform/environments/dev/02-app/main.tf (thêm DynamoDB GSI)

2. Commit & push:  git commit -m "feat: add product index to DynamoDB"

                   git push origin feature/product-index

3. PR tạo (GitHub): Workflow auto trigger

   - terraform validate ✓

   - terraform plan → comment vào PR

     ```

     Plan: 0 add, 1 change, 0 destroy

     - aws_dynamodb_table.kicks: Adding attribute "product_index"

     ```

   - ESLint check ✓

   - Unit test ✓

   → PR status = "Ready for review"

4. Review & approve: Team lead xem plan, code changes, approve

5. Merge to main:   PR merge vào kicks-production

                    GitHub auto push triggers deploy workflow

6. Deploy workflow:

   a) Build image (Dockerfile.evolution + new backend/src code)

      → Image URI: 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/kicks-shoes-backend:abc123def456

   

   b) Terraform plan & apply

      - terraform apply -var container_image=<URI>

      → DynamoDB table được update thêm GSI

      → ECS task definition được update với image mới

      → State file lưu vào S3

   

   c) ECS rollout

      - Force new deployment

      - Old task dừng dần, new task khởi động từng cái

      - Health check pass → traffic được route vào new task

   

   d) Post-deploy verify

      - /api/health → 200 ✓

      - DynamoDB query new index → success ✓

7. Result:  Backend chạy version mới với hạ tầng update, code + IaC đều sync.
6.5 Làm sao để biết trạng thái hiện tại
Cách 1: Xem Terraform state trực tiếp
cd infra/terraform/environments/dev/02-app

# List tất cả resource hiện có

terraform state list

# Xem detail của một resource

terraform state show aws_ecs_service.kicks

# Output của stack (lấy giá trị được define trong outputs.tf)

terraform output

terraform output alb_dns_name
Cách 2: AWS Console (visual check)
Vào EC2 -> Load Balancers -> xem ALB target group -> health status.
Vào ECS -> Cluster kicks-shoes-dev -> Service kicks-shoes-dev -> xem task count, status.
Vào CloudFormation (Terraform auto-generate stack) -> xem resource event log.
Cách 3: AWS CLI commands nhanh
# ECS service status

aws ecs describe-services --cluster kicks-shoes-dev --services kicks-shoes-dev --region ap-southeast-1 --query "services[0].{desired:desiredCount,running:runningCount,status:status}" --output table

# Target group health

aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:... --region ap-southeast-1

# Cloudwatch logs cuối cùng

aws logs tail /ecs/kicks-shoes-dev --follow --region ap-southeast-1
Cách 4: GitHub Actions workflow status
Push vào repository.
Vào Actions tab.
Click workflow runs → xem log chi tiết.
Nếu fail → red X, xem stage/step nào fail và error message.
6.6 Thứ tự tối ưu khi có thay đổi
Thay đổi loại
Cách làm tối ưu
Giải thích
Chỉ backend code thay đổi
Update container_image var, Terraform apply
Hạ tầng không đổi, chỉ rebuild + push image mới.
Chỉ Terraform .tf thay đổi
terraform plan review trước, rồi apply
Terraform sẽ nhận diện chỉ phần IaC thay đổi, backend code không rebuild.
Cả code lẫn IaC thay đổi
Pipeline tự handle: build image + apply Terraform
CI/CD sẽ bắt cả 2, tuần tự: build image trước, push, apply Terraform với image mới.
Chỉ Secret/Env thay đổi
Update Secrets Manager / task definition directly
Không cần Terraform/code change, chỉ update secret value.



7) AWS settings cho backend (bắt buộc)
7.1 Runtime environment settings
Setting
Bắt buộc
Nguồn cấu hình
Mục đích
AWS_REGION hoặc AWS_DEFAULT_REGION
Yes
ECS Task Definition (env)
Xác định region cho AWS SDK (DynamoDB, S3, Secrets).
DYNAMODB_TABLE_NAME
Yes (khi dùng DynamoDB)
ECS Task Definition (env)
Chỉ định bảng dữ liệu backend đọc/ghi.
DATABASE_PROVIDER
Khuyến nghị
ECS Task Definition (env)
Chọn nguồn dữ liệu runtime: mongodb/dynamodb/dual.
<FEATURE>_READ_SOURCE
Tùy feature
ECS Task Definition (env)
Bật đọc theo nguồn cho từng module (ví dụ PRODUCT_READ_SOURCE).
APP_CONFIG_SECRET_NAME
Yes
ECS Task Definition (env) + Secrets Manager
Tên secret app config để inject vào container.
PORT
Yes
ECS Task Definition (env)
Port backend lắng nghe trong container.
HOST
Yes
ECS Task Definition (env)
Nên dùng 0.0.0.0 để ALB/ECS truy cập được.
NODE_ENV
Yes
ECS Task Definition (env)
Chạy đúng profile production.


Lưu ý vận hành:

Nếu thiếu AWS_REGION hoặc DYNAMODB_TABLE_NAME, các route/probe DynamoDB sẽ fail.
Nếu HOST=localhost, target group sẽ unhealthy dù container vẫn chạy.
Không để secret hardcode trong source, luôn đọc từ Secrets Manager.
7.2 ECS và network settings liên quan backend
Setting hạ tầng
Giá trị khuyến nghị
Ý nghĩa
container_port
3000
Đồng bộ với app port, Docker EXPOSE và target group.
Health check path
/api/health
Endpoint bắt buộc cho ECS/ALB health check.
ECS subnet
Private subnets
Không public IP trực tiếp cho backend task.
SG rule ALB -> ECS
Chỉ mở vào port app
Tránh mở toàn bộ cổng từ internet vào ECS.
CloudWatch log group
/ecs/<project-env>
Tập trung log backend để tra lỗi nhanh.

7.3 IAM tối thiểu cho backend task role
DynamoDB: GetItem, PutItem, Query, Scan (đúng table ARN).
S3 upload bucket: PutObject, GetObject (đúng bucket ARN).
Secrets Manager: GetSecretValue (đúng secret ARN).
CloudWatch Logs: quyền ghi log stream cho container.


8) Các luồng backend thực hiện (runtime flows)
Flow 1 — API request cơ bản
Request đi qua CloudFront -> ALB -> ECS service.
Express xử lý middleware: CORS, body parser, security headers, logging.
Router chuyển vào controller/service tương ứng.
Kết quả trả về client và ghi log vào CloudWatch.
Flow 2 — Auth và phân quyền
User gọi route auth/login.
Backend xác thực user theo data source đang cấu hình.
Token/JWT được tạo và trả cho frontend.
Các route protected kiểm tra token và role trước khi xử lý nghiệp vụ.
Flow 3 — Đọc dữ liệu theo nguồn MongoDB/DynamoDB
Backend đọc setting nguồn dữ liệu (DATABASE_PROVIDER, <FEATURE>_READ_SOURCE).
Factory/repository chọn implementation phù hợp (Mongo hoặc Dynamo).
Service xử lý filter/sort/pagination rồi trả response thống nhất cho frontend.
Khi migration, có thể chuyển dần từng feature mà không ảnh hưởng toàn hệ thống.
Flow 4 — Upload ảnh và lưu object
Request upload qua route upload của backend.
Backend validate file/type/size trước khi lưu.
Ảnh được đẩy lên bucket/object storage theo cấu hình runtime.
URL ảnh được lưu lại cho entity liên quan (product/user/blog).
Flow 5 — Health và quan sát hệ thống
/api/health trả trạng thái process và uptime.
/api/health/dynamodb kiểm tra read/write thực tế với bảng DynamoDB.
ECS/ALB dùng kết quả health check để quyết định traffic và rollout.
Team theo dõi log/metric để xử lý sự cố sớm.
Flow 6 — Cron job nội bộ
Backend khởi động các cron (discount, flash sale, auto complete order, scheduler liên quan).
Mỗi job chạy theo lịch đã định và cập nhật trạng thái dữ liệu.
Log job được gửi về CloudWatch để truy vết lỗi theo thời điểm.


9) Matrix xử lý sự cố backend sau deploy
Triệu chứng
Nguyên nhân thường gặp
Cách kiểm tra nhanh
Cách xử lý
Target group unhealthy
Sai health path hoặc app không bind đúng host/port
Check health check path trên ALB + log container
Đặt health path /api/health, bind 0.0.0.0, đồng bộ PORT
ECS task crash loop
Thiếu env/secret runtime
Xem task stopped reason + CloudWatch logs
Bổ sung secret trong task definition/Secrets Manager
API timeout qua ALB
SG/NACL hoặc app xử lý chậm
Kiểm tra SG ALB -> ECS, xem p95 latency
Mở đúng rule SG, tối ưu endpoint chậm
/api/health/dynamodb fail
Sai table name/region/quyền IAM
Gọi trực tiếp endpoint health/dynamodb
Sửa env DYNAMODB_TABLE_NAME, region, task role policy
Frontend gọi API lỗi CORS
Origin chưa whitelist
Mở browser console và network
Cập nhật CORS allowlist trong backend config
Mixed content
Frontend HTTPS gọi backend HTTP
Browser console báo blocked insecure request
Dùng HTTPS cho API domain qua ALB/CloudFront
Scale-out không xảy ra
CPU chưa vượt target hoặc policy sai
Check ECS desired/running + CloudWatch CPU
Tăng tải test đúng endpoint, sửa target tracking policy



10) Rollback backend
Ưu tiên rollback theo task definition trước để khôi phục nhanh:

Xác định task definition ARN trước đó.
Update ECS service dùng ARN cũ + force new deployment.
Chờ service stable.
Verify lại /api/health và route cốt lõi.

Khi nào cần rollback bằng Terraform:

Sai cấu hình hạ tầng (SG/ALB/listener/secret wiring) do thay đổi IaC.
Cần quay lại trạng thái infra trước đó theo plan đã được kiểm soát.


11) Chuẩn viết tài liệu backend để ai đọc cũng hiểu
11.1 Nguyên tắc viết
Viết theo flow thời gian: trước deploy -> deploy -> sau deploy -> rollback.
Mỗi bước phải có 3 phần: Mục tiêu, Lệnh, Điều kiện pass.
Dùng bảng cho troubleshooting thay vì mô tả dài.
Tách rõ phần bắt buộc (Critical) và phần khuyến nghị (High/Medium).
Không nhúng chi tiết trùng lặp; link sang tài liệu gốc khi đã có.
11.2 Template ngắn cho mỗi thay đổi backend
Sao chép mẫu sau vào PR hoặc changelog backend:

Phạm vi thay đổi: endpoint/service/module nào.
Tác động runtime: CPU/memory/I/O/cache/DB.
Biến môi trường mới: tên biến, bắt buộc hay không.
Kế hoạch deploy: script/lệnh đã dùng.
Kế hoạch verify: endpoint nào cần test sau deploy.
Kế hoạch rollback: cách quay lại bản trước trong 5-10 phút.
11.3 Quy ước trình bày đề xuất cho team
Mỗi section tối đa 5-7 dòng, tránh khối chữ dài.
Lệnh thực thi để nguyên một dòng, không viết mơ hồ.
Dùng cùng tên thuật ngữ xuyên suốt: ECS service, task definition, target group, health check.
Nếu có số liệu (CPU target, timeout, retention days), ghi rõ con số cụ thể.


12) Bảng keyword nhanh (glossary)
Keyword
Ý nghĩa ngắn
Dùng khi nào
ECS Service
Dịch vụ chạy các task backend
Triển khai/rà soát trạng thái runtime
Task Definition
Bản mô tả container image, env, CPU/RAM
Mỗi lần update image/setting backend
Target Group
Nhóm đích ALB forward traffic vào ECS
Kiểm tra healthy/unhealthy
Health Check
Cơ chế kiểm tra sống của backend
Trước/sau deploy và rollout
Secrets Manager
Kho quản lý secret runtime
Lưu key/token/password an toàn
IAM Task Role
Quyền AWS của container backend
Truy cập DynamoDB/S3/Secrets
CloudWatch Logs
Nơi tập trung log backend
Điều tra lỗi và theo dõi vận hành
Rollback
Quay lại phiên bản ổn định trước đó
Khi release gây lỗi production/dev



13) Cross-reference tài liệu liên quan
Network stack: .AIDD/changes/001-dev-terraform-deploy/01-network.md
App stack: .AIDD/changes/001-dev-terraform-deploy/02-app.md
Backend predeploy checklist: docs/backend-predeployment-checklist.md
ECS demo checklist: docs/ecs-fargate-demo-checklist.md
Post-deploy checklist: docs/post-deploy-quick-verify-checklist.md
E2E deploy script: scripts/ecs-fargate-e2e.ps1
Predeploy audit script: scripts/predeploy-backend-audit.ps1


14) Definition of Done cho backend deploy
Release backend chỉ được coi là Done khi đạt đủ:

Toàn bộ check Critical trong predeploy audit pass.
ECS service stable, target group healthy.
GET /api/health và GET /api/health/dynamodb pass.
Có release note gồm image digest + thời gian deploy + người chịu trách nhiệm.
Rollback command đã được chuẩn bị và test được về mặt kỹ thuật.





