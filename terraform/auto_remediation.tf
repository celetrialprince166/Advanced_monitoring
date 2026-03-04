# =============================================================================
# Event-Driven Auto-Remediation (Post-Deployment 5xx Errors)
# =============================================================================
# Purpose: Detects sustained 5xx errors (not during active CodeDeploy deployment)
#          and triggers a Lambda to recycle the broken ECS tasks.
# =============================================================================

# 1. CloudWatch Alarm for Sustained 5xx
resource "aws_cloudwatch_metric_alarm" "remediation_5xx" {
  alarm_name          = "${var.environment}-notes-app-5xx-remediation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 120 # 3 x 120s = 6 minutes sustained
  statistic           = "Sum"
  threshold           = 10

  dimensions = {
    LoadBalancer = aws_lb.notes_app.arn_suffix
    TargetGroup  = aws_lb_target_group.notes_app.arn_suffix
  }

  alarm_actions = [aws_sns_topic.remediation.arn]
  # OK actions can be added if needed to notify when resolved

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-notes-app-5xx-remediation"
      Role = "auto-remediation-trigger"
    }
  )
}

# 2. SNS Topic
resource "aws_sns_topic" "remediation" {
  name = "${var.environment}-notes-app-remediation"
  tags = local.common_tags
}

# 3. SNS Subscription to Lambda
resource "aws_sns_topic_subscription" "remediation_lambda" {
  topic_arn = aws_sns_topic.remediation.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.remediation.arn
}

# 4. Allow SNS to invoke Lambda
resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediation.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.remediation.arn
}

# 5. Lambda Package (zip)
data "archive_file" "remediation_zip" {
  type        = "zip"
  source_file = "${path.module}/../scripts/auto-remediation/handler.py"
  output_path = "${path.module}/auto-remediation.zip"
}

# 6. Lambda Function
resource "aws_lambda_function" "remediation" {
  filename         = data.archive_file.remediation_zip.output_path
  source_code_hash = data.archive_file.remediation_zip.output_base64sha256
  function_name    = "${var.environment}-notes-app-remediation"
  role             = aws_iam_role.remediation_lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  # Prevent multiple alarms from triggering parallel executions
  reserved_concurrent_executions = 1

  environment {
    variables = {
      ECS_CLUSTER       = aws_ecs_cluster.notes_app.name
      ECS_SERVICE       = aws_ecs_service.notes_app.name
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  tags = local.common_tags
}

# 7. Lambda IAM Role
resource "aws_iam_role" "remediation_lambda" {
  name_prefix = "${var.environment}-remediation-lambda-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# 8. Lambda IAM Policy
resource "aws_iam_role_policy" "remediation_lambda" {
  name = "ecs-auto-remediation"
  role = aws_iam_role.remediation_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Basic Lambda execution logs
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.remediation_lambda.arn}:*"
      },
      {
        # Required for Idempotency check
        Effect = "Allow"
        Action = [
          "logs:FilterLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.remediation_lambda.arn}:*"
      },
      {
        # ECS actions to list and stop tasks
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:StopTask",
          "ecs:DescribeServices"
        ]
        Resource = [
          aws_ecs_cluster.notes_app.arn,
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.notes_app.name}/${aws_ecs_service.notes_app.name}",
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task/${aws_ecs_cluster.notes_app.name}/*"
        ]
      }
    ]
  })
}

# 9. CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "remediation_lambda" {
  name              = "/aws/lambda/${var.environment}-notes-app-remediation"
  retention_in_days = 30
  tags              = local.common_tags
}
