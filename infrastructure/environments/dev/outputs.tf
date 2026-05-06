output "vpc_id" { value = module.network.vpc_id }
output "dynamodb_table_name" { value = module.database.table_name }
output "assets_bucket_name" { value = module.storage_assets.bucket_id }
