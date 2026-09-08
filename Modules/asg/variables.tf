variable "name_prefix" {
  type        = string
  description = "Prefix for resource naming"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private Subnet IDs"
}

variable "ec2_sg_id" {
  type        = string
  description = "Security Group ID for EC2"
}

variable "target_group_arn" {
  type        = string
  description = "ALB Target Group ARN"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type"
}

variable "instance_profile_name" {
  type        = string
  default     = "LabInstanceProfile"
  description = "IAM Instance Profile Name"
}

variable "secret_arn" {
  type        = string
  description = "Secrets Manager Secret ARN"
}

variable "artifact_bucket" {
  type        = string
  description = "S3 Bucket Name for deployment artifact"
}

variable "artifact_key" {
  type        = string
  default     = "app.zip"
  description = "S3 Bucket key for application package"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum instances in ASG"
}

variable "max_size" {
  type        = number
  default     = 3
  description = "Maximum instances in ASG"
}

variable "desired_capacity" {
  type        = number
  default     = 2
  description = "Desired instances in ASG"
}

variable "cpu_target_value" {
  type        = number
  default     = 70.0
  description = "Target CPU utilization percentage"
}