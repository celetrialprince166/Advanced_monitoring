# =============================================================================
# SSH Key Pair — Jenkins EC2
# =============================================================================
# Generates a TLS private key and registers it with AWS as a key pair.
# Mirrors the pattern used in the existing terraform/key_pair.tf
# =============================================================================

resource "tls_private_key" "jenkins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins" {
  key_name   = "${var.environment}-jenkins-key"
  public_key = tls_private_key.jenkins.public_key_openssh

  tags = {
    Name = "${var.environment}-jenkins-key"
  }
}
