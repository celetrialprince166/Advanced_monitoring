# =============================================================================
# Outputs for Production Automation Add-Ons
# =============================================================================

# --- Auto Scaling Outputs ---
output "autoscaling_cpu_policy_arn" {
  description = "ARN of the CPU target tracking auto-scaling policy"
  value       = aws_appautoscaling_policy.notes_app_cpu.arn
}


output "ecs_service_scalable_target_id" {
  description = "The registered Application Auto Scaling target ID"
  value       = aws_appautoscaling_target.notes_app.id
}

# --- Auto Remediation Outputs ---
output "remediation_lambda_arn" {
  description = "ARN of the auto-remediation Lambda function"
  value       = aws_lambda_function.remediation.arn
}

output "remediation_lambda_name" {
  description = "Name of the auto-remediation Lambda function"
  value       = aws_lambda_function.remediation.function_name
}

output "remediation_sns_topic_arn" {
  description = "ARN of the SNS topic receiving the 5xx alarm"
  value       = aws_sns_topic.remediation.arn
}

output "remediation_alarm_name" {
  description = "Name of the 5xx CloudWatch alarm triggering remediation"
  value       = aws_cloudwatch_metric_alarm.remediation_5xx.alarm_name
}

output "remediation_log_group_name" {
  description = "Name of the CloudWatch log group for Lambda logs"
  value       = aws_cloudwatch_log_group.remediation_lambda.name
}
