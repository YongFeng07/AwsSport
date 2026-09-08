# assignment-rds: single-AZ sandbox MySQL instance. The DB subnet group still
# needs subnets in >= 2 AZs (an AWS hard requirement) even though the instance
# itself is single-AZ per the assignment's own assumptions.
resource "aws_db_subnet_group" "this" {
  name       = "sports-facility-booking-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "sports-facility-booking-db-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier     = "sports-facility-booking-rds"
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]

  multi_az            = false
  publicly_accessible = false

  # Sandbox environment: prioritize cheap/disposable over durability.
  skip_final_snapshot     = true
  backup_retention_period = 1
  deletion_protection     = false
  apply_immediately       = true

  tags = {
    Name = "sports-facility-booking-rds"
  }
}
# modules/rds/main.tf
resource "aws_iam_role" "rds_monitoring" {
  name = "sports-facility-booking-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}