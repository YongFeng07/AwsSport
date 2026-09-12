# ============================================================
# S3 Bucket 
# ============================================================

resource "aws_s3_bucket" "uploads" {
  bucket        = "sports-facility-booking-s3"
  force_destroy = true

  tags = {
    Name        = "sports-facility-booking-s3"
    Environment = "sandbox"
    Project     = "sports-facility-booking"
  }

  lifecycle {
    ignore_changes = [
      object_lock_configuration,
    ]
  }
}

# ============================================================
# Object Ownership — 
# ============================================================
resource "aws_s3_bucket_ownership_controls" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  rule {
    object_ownership = "ObjectWriter"  # ACLs enabled
  }
}

# ============================================================
# Block Public Access — 
# ============================================================
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ============================================================
# Bucket Policy 
# ===========================================================
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "allow_public" {
  bucket = aws_s3_bucket.uploads.id

  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid       = "AllowPublicRead"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.uploads.arn}/*"
      },
      {
        Sid       = "AllowPublicWrite"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.uploads.arn}/*"
      }
    ]
  })
}

# ============================================================
# Default Encryption 
# ============================================================
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ============================================================
# Outputs
# ============================================================
output "bucket_id" {
  description = "The ID/Name of the S3 bucket"
  value       = aws_s3_bucket.uploads.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.uploads.arn
}