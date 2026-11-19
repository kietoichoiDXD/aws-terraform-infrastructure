variable "aws_region" {
  description = "AWS region. Singapore is the initial Lightsail deployment fallback."
  type        = string
  default     = "ap-southeast-1"
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

variable "google_client_id" {
  description = "Optional Google OAuth client ID for Cognito federation. Keep its matching secret in a private Terraform variable file."
  type        = string
  default     = ""
}

variable "google_client_secret" {
  description = "Optional Google OAuth client secret for Cognito federation. Never commit this value."
  type        = string
  default     = ""
  sensitive   = true
}
