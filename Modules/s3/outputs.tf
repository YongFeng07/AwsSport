output "bucket_id" {
  description = "The ID/Name of the bucket"
  value       = aws_s3_bucket.uploads.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.uploads.arn
}