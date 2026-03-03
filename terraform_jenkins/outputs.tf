# =============================================================================
# Jenkins EC2 — Outputs
# =============================================================================

output "jenkins_url" {
  description = "URL to access Jenkins web UI"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to Jenkins server"
  value       = "ssh -i jenkins-key.pem ubuntu@${aws_instance.jenkins.public_ip}"
}

output "jenkins_private_key" {
  description = "SSH private key for Jenkins EC2 (terraform output -raw jenkins_private_key > jenkins-key.pem)"
  value       = tls_private_key.jenkins.private_key_pem
  sensitive   = true
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.jenkins.id
}
