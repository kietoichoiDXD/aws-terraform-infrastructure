variable "aws_region" {
  description = "AWS region. Jakarta is close to Vietnam; enable it in the account before use."
  type        = string
  default     = "ap-southeast-3"
}

variable "container_service_name" {
  description = "Unique Lightsail container service name in the selected region."
  type        = string
  default     = "scribeba-prod"
}

variable "container_power" {
  description = "Lightsail service size. micro (1 GB) is a low-cost starting point for the unified app."
  type        = string
  default     = "micro"

  validation {
    condition     = contains(["nano", "micro", "small", "medium", "large", "xlarge"], var.container_power)
    error_message = "Choose a supported Lightsail container power tier."
  }
}

variable "image_tag" {
  description = "Immutable image tag pushed to the ScribeBA ECR repository before deployment."
  type        = string
}

variable "allowed_origin" {
  description = "Optional exact browser origin. Leave empty to use the Lightsail HTTPS URL."
  type        = string
  default     = ""
}

variable "deploy_app" {
  description = "Set true after the selected immutable image tag has been pushed to ECR."
  type        = bool
  default     = false
}

variable "app_password" {
  description = "Shared sign-in password for the public app. Use a long random value."
  type        = string
  sensitive   = true
}

variable "session_secret" {
  description = "At least 32 random characters used to sign secure session cookies."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.session_secret) >= 32
    error_message = "session_secret must contain at least 32 characters."
  }
}

variable "nebius_api_key" {
  description = "Nebius API key. The value is stored in encrypted Terraform state; protect state access."
  type        = string
  sensitive   = true
}

variable "nebius_base_url" {
  description = "Nebius OpenAI-compatible API base URL."
  type        = string
  default     = "https://api.studio.nebius.ai/v1"
}

variable "nebius_model" {
  description = "Nebius model id configured for ScribeBA inference."
  type        = string
  default     = "Qwen/Qwen3-30B-A3B"
}

variable "enable_slack_notifications" {
  description = "Create optional AWS CloudWatch/GuardDuty to Slack notifications. Requires a Slack incoming webhook."
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for AWS infrastructure alerts; never commit this value."
  type        = string
  sensitive   = true
  default     = ""
}

variable "slack_channel" {
  description = "Slack channel name used by the optional AWS alerts module."
  type        = string
  default     = "aws-alerts"
}
