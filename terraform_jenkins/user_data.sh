#!/bin/bash
# =============================================================================
# Jenkins EC2 — User Data (Bootstrap Script)
# =============================================================================
# Runs on first boot. Installs Docker and prepares the deployment directory.
# Terraform provisioners will SSH in after boot to copy files and start Jenkins.
# =============================================================================

set -euo pipefail
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== Jenkins EC2 bootstrap started at $(date) ==="

# -----------------------------------------------
# 1. Install Docker & Utilities
# -----------------------------------------------
echo ">>> Installing Docker Engine and utilities..."
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release jq git unzip

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker ubuntu

# -----------------------------------------------
# 2. Setup Deployment Directory
# -----------------------------------------------
DEPLOY_DIR="/opt/jenkins-deploy/docker_jenkins"
echo ">>> Setting up deployment directory at $DEPLOY_DIR..."
mkdir -p "$DEPLOY_DIR/agent"
chown ubuntu:ubuntu -R /opt/jenkins-deploy

# Mark user_data as complete so provisioners know it's safe to proceed
touch /tmp/user_data_complete

echo "=== Jenkins EC2 bootstrap completed at $(date) ==="
