output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for ASG notifications"
  value       = aws_sns_topic.asg_updates.arn
}