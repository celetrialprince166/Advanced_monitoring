# =============================================================================
# Jenkins EC2 — Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region for the Jenkins EC2 instance"
  type        = string
  default     = "eu-west-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be in valid format (e.g., eu-west-1)."
  }
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^t[2-3]\\.(nano|micro|small|medium|large)", var.instance_type))
    error_message = "Instance type must be a valid t2 or t3 instance type."
  }
}

variable "environment" {
  description = "Environment name prefix for resource naming"
  type        = string
  default     = "jenkins"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to Jenkins (restrict to your IP in production)"
  type        = string
  default     = "0.0.0.0/0"
}

# --- Jenkins Credentials Variables ---

variable "jenkins_admin_user" {
  description = "Jenkins Admin Username"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins Admin Password"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "jenkins_aws_access_key_id" {
  description = "AWS Access Key ID for Jenkins"
  type        = string
  sensitive   = true
}

variable "jenkins_aws_secret_access_key" {
  description = "AWS Secret Access Key for Jenkins"
  type        = string
  sensitive   = true
}

variable "jenkins_ecr_registry" {
  description = "ECR Registry URL"
  type        = string
}

variable "jenkins_ec2_host" {
  description = "EC2 Host IP"
  type        = string
  default     = ""
}

variable "jenkins_ec2_ssh_key" {
  description = "EC2 SSH Private Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jenkins_db_username" {
  description = "Database Username"
  type        = string
}

variable "jenkins_db_password" {
  description = "Database Password"
  type        = string
  sensitive   = true
}

variable "jenkins_db_name" {
  description = "Database Name"
  type        = string
}

variable "jenkins_sonar_token" {
  description = "SonarCloud Token"
  type        = string
  sensitive   = true
}

variable "jenkins_slack_token" {
  description = "Slack Token"
  type        = string
  sensitive   = true
}

variable "jenkins_codedeploy_app" {
  description = "CodeDeploy App Name"
  type        = string
}

variable "jenkins_codedeploy_dg" {
  description = "CodeDeploy Deployment Group"
  type        = string
}

variable "jenkins_ecs_alb_dns" {
  description = "ECS ALB DNS Name"
  type        = string
}

variable "jenkins_ecs_cluster" {
  description = "ECS Cluster Name"
  type        = string
}

variable "jenkins_ecs_service" {
  description = "ECS Service Name"
  type        = string
}

variable "jenkins_ecs_exec_role" {
  description = "ECS Task Execution Role ARN"
  type        = string
}

variable "jenkins_ecs_task_role" {
  description = "ECS Task Role ARN"
  type        = string
}

variable "jenkins_otel_endpoint" {
  description = "OpenTelemetry Endpoint"
  type        = string
  default     = ""
}
