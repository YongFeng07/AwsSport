
resource "aws_s3_bucket" "uploads" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = var.bucket_name
    Environment = "sandbox"
    Project     = "sports-facility-booking"
  }
}


# Unblocks public access settings so we can apply a bucket policy.
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


data "aws_caller_identity" "current" {}


resource "aws_s3_bucket_policy" "allow_ec2_access" {
  bucket = aws_s3_bucket.uploads.id


  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid = "AllowEC2Access"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabInstanceProfile"
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      }
    ]
  })
}

output "bucket_id" {
  description = "The ID/Name of the S3 bucket"
  value       = aws_s3_bucket.uploads.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.uploads.arn
}