# ScribeBA AWS environment

This environment adds a low-cost, same-origin deployment for the ScribeBA React frontend and Flask API. It is isolated from the existing Kicks-Shoes ECS development environment.

## Architecture

- One 1 GB Lightsail container service (micro tier) for the unified app, with its built-in HTTPS endpoint.
- One private ECR repository with image scanning and immutable tags. Lightsail pulls from ECR using its dedicated image-puller role.
- No VPC, NAT Gateway, ALB, RDS, or always-on Kubernetes cluster.
- Optional `terraform-aws-modules/notify-slack/aws` SNS/Lambda module for AWS infrastructure alerts. It requires a Slack incoming webhook and is disabled by default. It does not configure ScribeBA's Slack ingestion integration.

Jakarta (`ap-southeast-3`) is the default region because it is geographically closer to Vietnam than Singapore. Enable the region in the AWS account before deploying. This choice is for latency/geography; AWS's published Lightsail container pricing is not lower there by default.

## Before deployment

Use Terraform CLI 1.10 or newer and AWS credentials with permissions limited to the resources in this environment.

1. Confirm AWS account access and enable `ap-southeast-3` in AWS Account settings.
2. Bootstrap an encrypted, versioned S3 bucket for Terraform state with `infrastructure/bootstrap/state`. Keep access restricted. S3 state contains the app password, session secret, and Nebius key because Lightsail container deployment environment variables are managed as Terraform values. The variables are marked sensitive for CLI output, but sensitive values still exist in state.
3. Copy `backend.hcl.example` to the ignored `backend.hcl` and set the real state bucket. Copy `terraform.tfvars.example` to ignored `terraform.tfvars`, then fill local values. Never commit either file.
4. Create a long random login password and at least 32 random characters for `session_secret`. Obtain a Nebius API key. The app starts in live mode.
5. Apply once with `deploy_app=false` to create only ECR (no running service charge). Build and push an immutable image tag to the ECR URL printed by Terraform, set `deploy_app=true`, and apply again to create the Lightsail service and deploy the app.
6. If using a custom domain, set `allowed_origin` to its exact HTTPS origin. Otherwise, the generated Lightsail HTTPS URL is used automatically.

## State and first initialization

The bootstrap root uses a local state file only for the bucket itself. Store that file securely and do not commit it. After creating the bucket, use its output in the ScribeBA backend config:

```powershell
terraform -chdir=infrastructure/bootstrap/state init -backend=false
terraform -chdir=infrastructure/bootstrap/state apply
terraform -chdir=infrastructure/bootstrap/state output -raw bucket_name

# Configure and migrate the bootstrap root to its own remote state:
Copy-Item infrastructure/bootstrap/state/backend.hcl.example infrastructure/bootstrap/state/backend.hcl
# Replace the placeholder bucket with the output above, then run:
terraform -chdir=infrastructure/bootstrap/state init -migrate-state -backend-config=backend.hcl

# In infrastructure/environments/scribeba:
Copy-Item backend.hcl.example backend.hcl
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan
```

Review the plan and estimate before applying. Do not apply from a pull request or from unreviewed commits. Budget for the fixed Lightsail service and ECR image storage. Set an AWS Budget alert before production use.

## Image delivery

The repo's existing GitHub Actions workflow publishes to GHCR. This environment uses private ECR, so a deployment workflow must authenticate with GitHub OIDC and push the selected image tag to ECR, then apply the versioned deployment. Do not add long-lived AWS access keys to GitHub secrets. The existing infrastructure repository pipeline auto-applies its legacy `dev` root on pushes to `main`; review and change that pipeline before merging any infrastructure change to `main`.

## Cost and limitations

Lightsail container service pricing currently starts at $7/month for nano; micro is approximately $10/month with 1 GB RAM. ECR storage/transfer, logs, and optional Slack alerting are additional. Check the live pricing page for the selected region. There is one node and no multi-AZ redundancy, so this is a cost-focused initial deployment rather than a high-availability design.

The current backend stores run and room state in local JSON files. Container replacement can lose that data. Migrate those files to durable storage before treating the service as a production system with important user data.

## Useful upstream modules

- [AWS Notify Slack](https://github.com/terraform-aws-modules/terraform-aws-notify-slack) for CloudWatch/GuardDuty SNS alerts.
- [AWS Lambda module](https://github.com/terraform-aws-modules/terraform-aws-lambda) for a future pay-per-use API migration.
- [API Gateway v2 module](https://github.com/terraform-aws-modules/terraform-aws-apigateway-v2) for a serverless API edge.
- [S3 bucket module](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket) for durable objects or Terraform state.
- [DynamoDB table module](https://github.com/terraform-aws-modules/terraform-aws-dynamodb-table) for persistent structured state.
- [CloudFront module](https://github.com/terraform-aws-modules/terraform-aws-cloudfront) for a separate static frontend and CDN.
