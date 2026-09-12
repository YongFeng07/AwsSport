data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_instance_profile" "lab" {
  name = var.instance_profile_name
}

# 1. EC2 啟動範本
resource "aws_launch_template" "app" {
  name_prefix   = "sports-facility-booking-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.ec2_sg_id]

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab.name
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    secret_arn      = var.secret_arn
    aws_region      = var.aws_region
    artifact_bucket = var.artifact_bucket
    artifact_key    = var.artifact_key
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "sports-facility-booking-ec2"
      App  = "sports-facility-booking"
    }
  }

  tags = {
    Name = "sports-facility-booking-lt"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 2. Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name = "sports-facility-booking-asg"

  vpc_zone_identifier       = var.private_subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      auto_rollback          = true
    }
  }

  tag {
    key                 = "Name"
    value               = "sports-facility-booking-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "App"
    value               = "sports-facility-booking"  # ← 修正拼寫
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 3. CPU 自動伸縮策略
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "sports-facility-booking-asg-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}

# 4. SNS 通知主題
resource "aws_sns_topic" "asg_updates" {
  name = "sports-facility-booking-asg-topic"
}

# 5. ASG 通知綁定
resource "aws_autoscaling_notification" "asg_notifications" {
  group_names = [aws_autoscaling_group.app.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.asg_updates.arn
}

# ============================================================
# CloudWatch Log Groups
# ============================================================
resource "aws_cloudwatch_log_group" "apache_access" {
  name              = "/aws/ec2/sports-facility-booking/apache-access"
  retention_in_days = 7

  tags = {
    Name = "sports-facility-booking-apache-access"
  }
}

resource "aws_cloudwatch_log_group" "apache_error" {
  name              = "/aws/ec2/sports-facility-booking/apache-error"  # ← 改為 apache-error
  retention_in_days = 7

  tags = {
    Name = "sports-facility-booking-apache-error"
  }
}

# ============================================================
# CloudWatch Dashboard
# ============================================================
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "sports-facility-booking-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum" }],
            ["AWS/RDS", "DatabaseConnections", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Sports Facility Booking - Key Metrics"
        }
      }
    ]
  })
}

# ============================================================
# SNS Email 訂閱
# ============================================================
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.asg_updates.arn
  protocol  = "email"
  endpoint  = "wongyf-wm25@student.tarc.edu.my"
}

# ============================================================
# CloudWatch Alarm - High CPU
# ============================================================
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "sports-facility-booking-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GroupAverageCPUUtilization"  # ← 修正為 ASG 指標
  namespace           = "AWS/AutoScaling"              # ← 修正為 AutoScaling
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "EC2 CPU usage exceeds 70%"
  alarm_actions       = [aws_sns_topic.asg_updates.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}