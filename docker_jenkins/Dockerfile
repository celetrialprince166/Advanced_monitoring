# =============================================================================
# Jenkins Controller — Custom Docker Image
# =============================================================================
# Base: jenkins/jenkins:lts-jdk21
# Additions:
#   - Docker CLI (required for docker-workflow plugin to spawn Docker agents)
#   - Pre-installs all required plugins via jenkins-plugin-cli
#   - Skips the first-run setup wizard
#   - Configures JCasC (Jenkins Configuration as Code) path
# =============================================================================

FROM jenkins/jenkins:lts-jdk21

# --- Install Docker CLI (as root) ---
# The docker-workflow plugin runs `docker` from the controller to pull/run
# agent images. Without docker CLI here, agent { docker { } } stages fail.
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | \
       gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
       https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
       tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*
USER jenkins

# Skip the setup wizard entirely
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# JCasC — tell Jenkins where to find the configuration YAML
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc

# Install plugins from the plugins.txt list
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
# Convert Windows CRLF to Linux LF, otherwise jenkins-plugin-cli fails parsing the names
RUN sed -i 's/\r$//' /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Create the JCasC directory
RUN mkdir -p /var/jenkins_home/casc

# Expose ports
EXPOSE 8080 50000
