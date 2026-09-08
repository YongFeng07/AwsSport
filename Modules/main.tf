provider "aws" {
  region = var.aws_region
}

# 1. VPC 模块
module "vpc" {
  source               = "./modules/vpc"
  name_prefix          = "sports-facility-booking-vpc"
  vpc_cidr             = "172.16.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["172.16.0.0/20", "172.16.16.0/20"]
  private_subnet_cidrs = ["172.16.128.0/20", "172.16.144.0/20"]
}

# 2. 安全组模块
module "security_groups" {
  source      = "./modules/security-groups"
  name_prefix = "sports-facility-booking-sg"
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr
}

# 3. S3 存储桶模块
module "s3" {
  source      = "./modules/s3"
  name_prefix = var.name_prefix
  bucket_name = "sports-facility-booking-s3-uploads"
}

# 4. ALB 负载均衡模块
module "alb" {
  source            = "./modules/alb"
  name_prefix       = "sports-facility-booking-alb-sg"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

# 5. RDS 数据库模块
module "rds" {
  source             = "./modules/rds"
  name_prefix        = "sports-facility-booking-rds"
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id
  db_name            = "sports_booking_db"
  db_username        = "admin"
  db_password        = var.db_password
}

# 6. Secrets Manager 密钥模块
module "secrets" {
  source      = "./modules/secrets"
  name_prefix = "sports-facility-booking-secret"
  db_host     = module.rds.db_address
  db_port     = module.rds.db_port
  db_name     = "sports_booking_db"
  db_username = "admin"
  db_password = var.db_password
}

# 7. ASG 弹性伸缩组模块
module "asg" {
  source             = "./modules/asg"
  name_prefix        = "sports-facility-booking-asg"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ec2_sg_id          = module.security_groups.ec2_sg_id
  target_group_arn   = module.alb.target_group_arn
  instance_type      = "t3.medium"
  secret_arn         = module.secrets.secret_arn
  artifact_bucket    = module.s3.bucket_id
  aws_region         = var.aws_region
}