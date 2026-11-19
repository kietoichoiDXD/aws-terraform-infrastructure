output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "alb_listener_arn" {
  description = "ARN of the HTTP listener used by the ECS target service."
  value       = aws_lb_listener.http.arn
}
