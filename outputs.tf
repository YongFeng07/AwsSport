# 应用访问入口域名（直接在浏览器访问此 URL）
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

# ALB 的 ARN
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

# RDS 数据库连接 Endpoint (带有端口号)
output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = module.rds.db_endpoint
}

# S3 上传存储桶名称
# output "s3_bucket_name" {
#   description = "Name of the S3 bucket for uploads"
#   value       = module.s3.bucket_id
# }

# Secrets Manager 密钥 ARN
# output "secret_arn" {
#   description = "ARN of the Secrets Manager secret"
#   value       = module.secrets.secret_arn
# }