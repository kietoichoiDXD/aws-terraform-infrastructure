# ScribeBA AWS environment

This environment creates the ScribeBA ECR repository and Lightsail container service. A separate local-only script creates the app deployment. It is isolated from the existing Kicks-Shoes ECS development environment.

## Architecture

- One 1 GB Lightsail container service (micro tier) for the unified app, with its built-in HTTPS endpoint.
- One private ECR repository with image scanning, immutable tags, and a lifecycle rule that keeps the 10 most recent images. Lightsail pulls from ECR using its dedicated image-puller role.
- No VPC, NAT Gateway, ALB, RDS, or always-on Kubernetes cluster.
- Terraform has no application credentials, webhook values, or runtime environment variables as inputs.

Jakarta (`ap-southeast-3`) is the default region because it is geographically closer to Vietnam than Singapore. Enable the region in the AWS account before deploying. This choice is for latency/geography; AWS's published Lightsail container pricing is not lower there by default.

## Before deployment

Use Terraform CLI 1.10 or newer and AWS credentials with permissions limited to the resources in this environment.

1. Confirm AWS account access and enable `ap-southeast-3` in AWS Account settings.
2. Bootstrap an encrypted, versioned S3 bucket for Terraform state with `infrastructure/bootstrap/state`. Keep state-bucket access restricted.
3. Copy `backend.hcl.example` to the ignored `backend.hcl` and set the real state bucket. Copy `terraform.tfvars.example` to ignored `terraform.tfvars`. These Terraform values only configure the AWS region, service name, and service size.
4. Apply Terraform to create ECR, the Lightsail service, and ECR pull access. **The Lightsail service has a fixed monthly charge as soon as it is created**, even before the app is deployed.
5. Build the application image and push it to the ECR repository output by Terraform using an immutable git-SHA tag.
6. Copy `deploy-secrets.local.example.json` to the ignored `deploy-secrets.local.json` and fill it locally, or set the listed values in the current PowerShell process environment. Never commit the local file or print its values.
7. Run `./scripts/deploy-lightsail.ps1 -ImageTag <git-sha>`. The script creates a temporary JSON request file, submits it through AWS CLI, and removes the file in `finally`.
8. If using a custom domain, set `SCRIBEBA_ALLOWED_ORIGIN` to its exact HTTPS origin. Otherwise, the script uses the generated Lightsail HTTPS URL.

## Runtime secret visibility

App credentials are absent from Terraform variables, Terraform state, and GitHub code. The local script sends them to the Lightsail deployment API as container environment values. They are not exposed through the public HTTP endpoint by this configuration, but AWS principals with permission to read Lightsail deployments can read deployment configuration. The running app also receives the values in its process environment. This is an appropriate no-state-secret path when AWS deployment-read permissions are tightly restricted; it is not a secrets-at-runtime service boundary.

Lightsail does not provide native Secrets Manager injection into container environment variables. If secrets must remain out of the Lightsail deployment configuration itself, use a runtime such as ECS/Fargate with Secrets Manager task-definition references and a narrowly scoped task role. Do not grant a Lightsail container broad access to a secret store without a supported workload identity.

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

The infrastructure GitHub Actions workflow only runs Terraform formatting and validation; it does not apply infrastructure or deploy images. The deployment script is intentionally local-only and does not require GitHub secrets. A future CI deployment must use GitHub OIDC with least-privilege permissions. Do not add long-lived AWS access keys, app passwords, Nebius keys, Slack webhooks, or runtime environment files to GitHub.

## Cost and limitations

Lightsail container service pricing currently starts at $7/month for nano; micro is approximately $10/month with 1 GB RAM. ECR storage/transfer, logs, and optional Slack alerting are additional. Check the live pricing page for the selected region. There is one node and no multi-AZ redundancy, so this is a cost-focused initial deployment rather than a high-availability design.

The current backend stores run and room state in local JSON files. Container replacement can lose that data. Migrate those files to durable storage before treating the service as a production system with important user data.

The AWS Notify Slack module is not included in this environment because its webhook would become an infrastructure input. Configure AWS alerting separately through an approved secret-delivery path if needed; it does not configure ScribeBA's Slack ingestion.

## Useful upstream modules

- [AWS Lambda module](https://github.com/terraform-aws-modules/terraform-aws-lambda) for a future pay-per-use API migration.
- [API Gateway v2 module](https://github.com/terraform-aws-modules/terraform-aws-apigateway-v2) for a serverless API edge.
- [S3 bucket module](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket) for durable objects or Terraform state.
- [DynamoDB table module](https://github.com/terraform-aws-modules/terraform-aws-dynamodb-table) for persistent structured state.
- [CloudFront module](https://github.com/terraform-aws-modules/terraform-aws-cloudfront) for a separate static frontend and CDN.

If an earlier deployment applied app secrets through Terraform, rotate those secrets and review all historical S3 state object versions and Lightsail deployment versions; removing variables from the current configuration does not erase previously stored copies.
