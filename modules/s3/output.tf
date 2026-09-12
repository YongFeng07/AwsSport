output "bucket_id" {
  description = "The ID/Name of the S3 bucket"
  value       = var.bucket_name
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = "arn:aws:s3:::${var.bucket_name}"
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = "${var.bucket_name}.s3.amazonaws.com"
}