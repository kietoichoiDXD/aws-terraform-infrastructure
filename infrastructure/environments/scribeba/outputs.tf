output "app_url" {
  description = "Public HTTPS URL for the service. A deployment must be installed separately before the URL serves the app."
  value       = aws_lightsail_container_service.app.url
}

output "ecr_repository_url" {
  description = "Push application images to this ECR repository before deployment."
  value       = aws_ecr_repository.app.repository_url
}
