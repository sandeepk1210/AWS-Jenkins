#!/bin/bash

# Function to handle errors
handle_error() {
    echo "ERROR: $1"
    exit 1
}

# Update the system and install required packages
echo "INFO: Updating system and installing required packages"
sudo yum update -y || handle_error "Failed to update system."
sudo yum install -y wget jq git || handle_error "Failed to install required packages."

# Jenkins repo is added to yum.repos.d
echo "INFO: Adding Jenkins repository"
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo || handle_error "Failed to add Jenkins repo."

# Import key from Jenkins
echo "INFO: Importing Jenkins key"
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key || handle_error "Failed to import Jenkins key."

# Install Amazon Corretto 17
echo "INFO: Installing Amazon Corretto 17"
sudo yum install -y java-17-amazon-corretto || handle_error "Failed to install Amazon Corretto 17."

# Install Jenkins
echo "INFO: Installing Jenkins"
sudo yum install -y jenkins || handle_error "Failed to install Jenkins."

# Enable Jenkins service
echo "INFO: Enabling Jenkins service"
sudo systemctl enable jenkins || handle_error "Failed to enable Jenkins service."

# Start Jenkins service
echo "INFO: Starting Jenkins service"
sudo systemctl start jenkins || handle_error "Failed to start Jenkins service."

# Jenkins Initialization Script
echo "INFO: Applying Jenkins Initialization Script"
sudo mkdir -p /var/lib/jenkins/init.groovy.d || handle_error "Failed to create init directory."
sudo cat <<EOF > /var/lib/jenkins/init.groovy.d/init_jenkins.groovy
import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.getInstanceOrNull()
if (instance != null) {
    def hudsonRealm = new HudsonPrivateSecurityRealm(false)
    hudsonRealm.createAccount("admin", "admin")
    instance.setSecurityRealm(hudsonRealm)

    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    strategy.setAllowAnonymousRead(false)
    instance.setAuthorizationStrategy(strategy)

    InstallState.INITIAL_SETUP_COMPLETED.initializeState()
    instance.save()
}
EOF

# Set ownership of the initialization script
echo "INFO: Setting ownership for initialization script"
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/ || handle_error "Failed to set ownership for initialization script."
sudo chmod 644 /var/lib/jenkins/init.groovy.d/init_jenkins.groovy || handle_error "Failed to set permissions for initialization script."

# Restart Jenkins to apply initialization script
echo "INFO: Restarting Jenkins after initialization script"
sudo systemctl restart jenkins || handle_error "Failed to restart Jenkins."

# Get the initialAdminPassword
ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword) || handle_error "Failed to retrieve Jenkins initial admin password."

# Install Jenkins Plugins
echo "INFO: Installing Jenkins plugins"
sudo wget http://localhost:8080/jnlpJars/jenkins-cli.jar || handle_error "Failed to download Jenkins CLI."
sudo java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:admin install-plugin git matrix-auth job-dsl -deploy || handle_error "Failed to install Jenkins plugins."

# Set System Message
echo "INFO: Setting system message in Jenkins"
CRUMB=$(curl -u "admin:admin" -s 'http://localhost:8080/crumbIssuer/api/json' | jq -r '.crumb') || handle_error "Failed to get Jenkins crumb."
curl -X POST -u "admin:admin" http://localhost:8080/scriptText \
  -H "Jenkins-Crumb: $CRUMB" \
  --data-urlencode "script=Jenkins.instance.setSystemMessage('Jenkins Setup Complete')" || handle_error "Failed to set system message in Jenkins."

# Clone the Git repository containing the EC2 job DSL script
echo "INFO: Cloning Git repository containing EC2 Job DSL script"
git clone https://github.com/sandeepk1210/AWS-Jenkins.git /var/lib/jenkins/jobs || handle_error "Failed to clone Git repository."

# Check if the required DSL script exists
if [ ! -f /var/lib/jenkins/jobs/create-ec2-job.groovy ]; then
    handle_error "create-ec2-job.groovy file not found in the cloned repository."
fi

# Create the EC2 instance job using Jenkins Job DSL plugin
echo "INFO: Creating EC2 Job using Job DSL"
sudo java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:admin create-job create-ec2-job < /var/lib/jenkins/jobs/create-ec2-job.groovy || handle_error "Failed to create EC2 job using Job DSL."

# Clean up temp job DSL file
echo "INFO: Cleaning up temporary job DSL file"
rm -f /var/lib/jenkins/jobs/create-ec2-job.groovy || handle_error "Failed to remove temporary job DSL file."

# Restart Jenkins to finalize configurations
echo "INFO: Restarting Jenkins after creating EC2 job"
sudo systemctl restart jenkins || handle_error "Failed to restart Jenkins."

echo "INFO: Jenkins restarted successfully."
