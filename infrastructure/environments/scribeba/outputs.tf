output "app_url" {
  description = "Public HTTPS URL for the service. A deployment must be installed separately before the URL serves the app."
  value       = aws_lightsail_container_service.app.url
}

output "ecr_repository_url" {
  description = "Push application images to this ECR repository before deployment."
  value       = aws_ecr_repository.app.repository_url
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID for ScribeBA account registration and login."
  value       = aws_cognito_user_pool.app.id
}

output "cognito_client_id" {
  description = "Public web client ID used by the ScribeBA Cognito OAuth flow."
  value       = aws_cognito_user_pool_client.app.id
}

output "cognito_domain" {
  description = "Cognito hosted sign-in domain for email registration and optional Google federation."
  value       = "https://${aws_cognito_user_pool_domain.app.domain}.auth.${var.aws_region}.amazoncognito.com"
}
