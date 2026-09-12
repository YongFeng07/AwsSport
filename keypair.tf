# ============================================================
# Key Pair — 用於 SSH 連線 EC2 (備援，主要使用 SSM)
# ============================================================

# 產生 RSA 私鑰
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 建立 AWS Key Pair
resource "aws_key_pair" "this" {
  key_name   = "sports-facility-booking-keypair"
  public_key = tls_private_key.this.public_key_openssh

  tags = {
    Name = "sports-facility-booking-keypair"
  }
}

# 將私鑰儲存為本機檔案
resource "local_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${path.root}/keys/sports-facility-booking-keypair.pem"
  file_permission = "0400"
}

# 輸出
output "key_name" {
  description = "Name of the created key pair"
  value       = aws_key_pair.this.key_name
}

output "private_key_path" {
  description = "Path to the private key file"
  value       = local_file.private_key.filename
}