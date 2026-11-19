output "app_url" {
  description = "Public HTTPS URL for the ScribeBA container service."
  value       = aws_lightsail_container_service.app.url
}

output "ecr_repository_url" {
  description = "Push application images to this ECR repository before deployment."
  value       = aws_ecr_repository.app.repository_url
}

output "slack_alert_topic_arn" {
  description = "SNS topic consumed by the optional AWS-to-Slack notifications module."
  value       = try(module.notify_slack[0].slack_topic_arn, null)
}
