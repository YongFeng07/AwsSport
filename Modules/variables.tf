variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "sports-facility-booking"
}

variable "db_username" {
  description = "Master username for the RDS MySQL instance."
  type        = string
  default     = "admin" # Master 账号名字
}

variable "db_password" {
  description = "Master password for the RDS MySQL instance."
  type        = string
  default     = "Admin1234!!!!" # 直接在这里写密码
  sensitive   = true
}