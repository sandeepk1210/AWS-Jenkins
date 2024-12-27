#!/bin/bash
sudo yum update -y
sudo yum install -y wget jq

# Jenkins repo is added to yum.repos.d
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

# Import key from Jenkins
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Amazon Corretto 17
echo "INFO: Install Amazon Corretto 17"
sudo yum install -y java-17-amazon-corretto

# Install Jenkins
echo "INFO: Install Jenkins"
sudo yum install -y jenkins

# Enable Jenkins service
echo "INFO: Enable Jenkins"
sudo systemctl enable jenkins

# Start Jenkins service
echo "INFO: Start Jenkins"
sudo systemctl start jenkins

# Wait for Jenkins to start
echo "INFO: Sleeping for 30 seconds to allow Jenkins to start"
sleep 30

# Jenkins Initialization Script
echo "INFO: Jenkins Initialization Script"
sudo mkdir -p /var/lib/jenkins/init.groovy.d
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

# Set ownership
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/
sudo chmod 644 /var/lib/jenkins/init.groovy.d/init_jenkins.groovy

# Restart Jenkins to apply initialization script
echo "INFO: Restarting Jenkins after initialization script"
sudo systemctl restart jenkins

# Wait for Jenkins to restart
echo "INFO: Sleeping for 30 seconds to allow Jenkins to restart"
sleep 30

# Get the initialAdminPassword
ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Install Jenkins Plugins
echo "INFO: Installing Plugins"
sudo wget http://localhost:8080/jnlpJars/jenkins-cli.jar
sudo java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:admin install-plugin git matrix-auth job-dsl -deploy

# Set System Message
echo "INFO: Setting System Message"
CRUMB=$(curl -u "admin:admin" -s 'http://localhost:8080/crumbIssuer/api/json' | jq -r '.crumb')
curl -X POST -u "admin:admin" http://localhost:8080/scriptText \
  -H "Jenkins-Crumb: $CRUMB" \
  --data-urlencode "script=Jenkins.instance.setSystemMessage('Jenkins Setup Complete')"

# Clone the Git repository containing the EC2 job DSL script
echo "INFO: Cloning Git repository containing EC2 Job DSL script"
git clone https://github.com/sandeepk1210/AWS-Jenkins.git /var/lib/jenkins/jobs

# Create the EC2 instance job using Jenkins Job DSL plugin
echo "INFO: Creating EC2 Job using Job DSL"
sudo java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:admin create-job create-ec2-job < /var/lib/jenkins/jobs/create-ec2-job-dsl.groovy

# Clean up temp job DSL file
rm -f /var/lib/jenkins/jobs/create-ec2-job-dsl.groovy

# Restart Jenkins to finalize configurations
echo "INFO: Restarting Jenkins after creating EC2 job"
sudo systemctl restart jenkins
