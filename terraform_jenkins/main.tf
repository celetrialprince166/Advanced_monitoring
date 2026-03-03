# =============================================================================
# Jenkins EC2 — Main Terraform Configuration
# =============================================================================
# Purpose: Provision a single t3.medium EC2 instance to host Jenkins
# VPC/Subnet: Default (AWS picks the default VPC and a default subnet)
# =============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# =============================================================================
# AWS Provider
# =============================================================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "NotesApp-Jenkins"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# =============================================================================
# Data Sources
# =============================================================================

# Latest Ubuntu 22.04 LTS AMI (same lookup as existing terraform/)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# =============================================================================
# EC2 Instance — Jenkins Controller
# =============================================================================
resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # Default VPC / default subnet — no subnet_id means AWS picks one
  vpc_security_group_ids = [aws_security_group.jenkins.id]

  # SSH key
  key_name = aws_key_pair.jenkins.key_name

  # Root volume — 30 GB for Docker images + Jenkins data
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.environment}-jenkins-root-volume"
    }
  }

  # Bootstrap script — installs Docker and prepares directories
  user_data = templatefile("${path.module}/user_data.sh", {})

  # Metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.environment}-jenkins-server"
  }

  depends_on = [
    aws_security_group.jenkins,
    aws_key_pair.jenkins
  ]
}

# =============================================================================
# Automated Configuration via SSH (Bypassing 16KB user_data limit)
# =============================================================================
resource "null_resource" "jenkins_config" {
  # Trigger re-run if the instance changes
  triggers = {
    instance_id = aws_instance.jenkins.id
  }

  # Connection details for all provisioners in this resource
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.jenkins.private_key_pem
    host        = aws_instance.jenkins.public_ip
    timeout     = "5m"
  }

  # 1. Wait for user_data.sh to finish (creates directories and installs docker)
  provisioner "remote-exec" {
    inline = [
      "set -x",
      "echo 'Waiting for user_data.sh to complete...'",
      "while [ ! -f /tmp/user_data_complete ]; do sleep 5; done",
      "echo 'user_data.sh completed!'"
    ]
  }

  # 2. Upload the entire docker_jenkins folder to /tmp first (to avoid permission issues)
  provisioner "file" {
    source      = "${path.module}/../docker_jenkins"
    destination = "/tmp/docker_jenkins"
  }

  # 3. Create the configuration script using a templatefile
  # This avoids putting sensitive variables directly in an inline remote-exec block,
  # which causes Terraform to suppress all output and makes debugging impossible.
  provisioner "file" {
    content = templatefile("${path.module}/env_gen.sh.tftpl", {
      jenkins_admin_user            = var.jenkins_admin_user
      jenkins_admin_password        = var.jenkins_admin_password
      jenkins_aws_access_key_id     = var.jenkins_aws_access_key_id
      jenkins_aws_secret_access_key = var.jenkins_aws_secret_access_key
      aws_region                    = var.aws_region
      jenkins_ecr_registry          = var.jenkins_ecr_registry
      jenkins_ec2_host              = var.jenkins_ec2_host
      jenkins_ec2_ssh_key           = base64encode(var.jenkins_ec2_ssh_key)
      jenkins_db_username           = var.jenkins_db_username
      jenkins_db_password           = var.jenkins_db_password
      jenkins_db_name               = var.jenkins_db_name
      jenkins_sonar_token           = var.jenkins_sonar_token
      jenkins_slack_token           = var.jenkins_slack_token
      jenkins_codedeploy_app        = var.jenkins_codedeploy_app
      jenkins_codedeploy_dg         = var.jenkins_codedeploy_dg
      jenkins_ecs_alb_dns           = var.jenkins_ecs_alb_dns
      jenkins_ecs_cluster           = var.jenkins_ecs_cluster
      jenkins_ecs_service           = var.jenkins_ecs_service
      jenkins_ecs_exec_role         = var.jenkins_ecs_exec_role
      jenkins_ecs_task_role         = var.jenkins_ecs_task_role
      jenkins_otel_endpoint         = var.jenkins_otel_endpoint
    })
    destination = "/tmp/env_gen.sh"
  }

  # 4. Move files to deployment directory and execute the configuration script
  provisioner "remote-exec" {
    inline = [
      "set -x",
      "echo 'Moving files to deployment directory...'",
      "sudo rm -rf /opt/jenkins-deploy/docker_jenkins",
      "sudo mv /tmp/docker_jenkins /opt/jenkins-deploy/",
      "sudo chown -R ubuntu:ubuntu /opt/jenkins-deploy/",

      "cd /opt/jenkins-deploy/docker_jenkins",
      "sudo rm -f .env",

      "echo 'Executing configuration script...'",
      "chmod +x /tmp/env_gen.sh",
      "sed -i 's/\\r$//' /tmp/env_gen.sh",
      "echo '--- START OF env_gen.sh ---'",
      "cat /tmp/env_gen.sh",
      "echo '--- END OF env_gen.sh ---'",
      "sudo /tmp/env_gen.sh",
      "rm -f /tmp/env_gen.sh",

      "echo 'Building agent...'",
      "sudo docker build -t jenkins-ci-agent:latest ./agent/",
      "echo 'Starting Jenkins...'",
      "sudo docker compose up -d --build"
    ]
  }
}
