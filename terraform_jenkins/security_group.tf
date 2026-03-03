# =============================================================================
# Jenkins Security Group
# =============================================================================
# Ports open:
#   - 22   (SSH)        — for admin access
#   - 8080 (Jenkins UI) — web interface
#   - All outbound      — Docker pulls, apt-get, AWS API calls
# =============================================================================

resource "aws_security_group" "jenkins" {
  name_prefix = "${var.environment}-jenkins-"
  description = "Security group for Jenkins EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.environment}-jenkins-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- Inbound Rules ---

# SSH — port 22
resource "aws_vpc_security_group_ingress_rule" "jenkins_ssh" {
  security_group_id = aws_security_group.jenkins.id
  description       = "SSH access to Jenkins server"

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_ssh_cidr

  tags = { Name = "jenkins-ssh-inbound" }
}

# Jenkins UI — port 8080
resource "aws_vpc_security_group_ingress_rule" "jenkins_ui" {
  security_group_id = aws_security_group.jenkins.id
  description       = "Jenkins web UI"

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = { Name = "jenkins-ui-inbound" }
}

# --- Outbound Rules ---

# All outbound traffic
resource "aws_vpc_security_group_egress_rule" "jenkins_all_outbound" {
  security_group_id = aws_security_group.jenkins.id
  description       = "Allow all outbound (Docker pulls, apt, AWS API)"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = { Name = "jenkins-all-outbound" }
}
