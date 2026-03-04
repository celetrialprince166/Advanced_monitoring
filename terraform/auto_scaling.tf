# =============================================================================
# ECS Service Auto Scaling
# =============================================================================
# Purpose: Automatically scale the ECS service in/out based on CPU usage and
#          ALB request count per target.
# =============================================================================

resource "aws_appautoscaling_target" "notes_app" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.notes_app.name}/${aws_ecs_service.notes_app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# =============================================================================
# Target Tracking Policy: CPU Utilization
# =============================================================================
resource "aws_appautoscaling_policy" "notes_app_cpu" {
  name               = "${var.environment}-notes-app-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.notes_app.resource_id
  scalable_dimension = aws_appautoscaling_target.notes_app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.notes_app.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

