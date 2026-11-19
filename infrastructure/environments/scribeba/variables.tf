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
