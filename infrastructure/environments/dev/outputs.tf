output "alb_dns_name" {
  description = "Địa chỉ truy cập ứng dụng từ internet"
  value       = module.load_balancer.alb_dns_name
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}
