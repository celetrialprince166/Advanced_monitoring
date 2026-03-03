# =============================================================================
# Jenkins CI Agent — Docker CLI + AWS CLI v2 + Utilities
# =============================================================================
# Purpose: Ephemeral build agent for Docker build/push and AWS deploy stages.
# Used by Jenkinsfile as: agent { docker { image 'jenkins-ci-agent:latest' } }
#
# Built once on the EC2 host with:
#   docker build -t jenkins-ci-agent:latest ./docker_jenkins/agent/
# =============================================================================

FROM ubuntu:22.04

# Avoid interactive prompts during apt install
ENV DEBIAN_FRONTEND=noninteractive

# --- System Utilities ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    bash \
    unzip \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# --- Docker CLI (client only — no daemon, uses host socket) ---
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
       gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
       https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
       tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# --- AWS CLI v2 ---
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip /tmp/awscliv2.zip -d /tmp/ \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

# --- Verify installations ---
RUN docker --version && aws --version && jq --version && git --version

# Default shell
CMD ["/bin/bash"]
