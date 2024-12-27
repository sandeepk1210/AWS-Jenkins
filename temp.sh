#!/bin/bash
sudo yum update -y
sudo yum install -y wget jq
# Jenkins repo is added to yum.repos.d
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

# Import key from Jenkins
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# To install Amazon Corretto 17
echo "INFO: Install Amazon Corretto 17"
sudo yum install -y java-17-amazon-corretto

# Install Jenkins
echo "INFO: Install Jenkins"
yum install jenkins -y

# You can enable the Jenkins service to start at boot with the command:
echo "INFO: Enable Jenkins"
systemctl enable jenkins

# You can start the Jenkins service with the command:
echo "INFO: Start Jenkins"
systemctl start jenkins

# You can check the status of the Jenkins service using the command:
echo "INFO: Status check Jenkins"
systemctl status jenkins

# Wait for Jenkins to start and generate the initialAdminPassword
echo "INFO: Jenkin sleeping for 30 secs"
sleep 30

# Jenkins Initialization Script
mkdir -p /var/lib/jenkins/init.groovy.d
cat <<EOF1 > /var/lib/jenkins/init.groovy.d/init_jenkins.groovy
import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

InstallState.INITIAL_SETUP_COMPLETED.initializeState()
instance.save()

// 2. Create a Sample Jenkins Job
import jenkins.model.*
import hudson.model.*
import javaposse.jobdsl.plugin.ExecuteDslScripts

def jobName = "sample-job"
def jobDescription = "This is a sample Jenkins job created via init script."
def dslScript = '''
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }
}
'''

if (Jenkins.instance.getItem(jobName) == null) {
    def job = Jenkins.instance.createProject(hudson.model.FreeStyleProject, jobName)
    job.setDescription(jobDescription)
    def scriptSource = new javaposse.jobdsl.plugin.ExecuteDslScripts.ScriptLocation(
        javaposse.jobdsl.plugin.ExecuteDslScripts.ScriptLocation.SCRIPT,
        dslScript,
        ""
    )
    def executeDslScripts = new javaposse.jobdsl.plugin.ExecuteDslScripts()
    executeDslScripts.setScriptLocation(scriptSource)
    executeDslScripts.run()
    job.save()
}
EOF1

chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/
systemctl restart jenkins

# Get the initialAdminPassword
ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

echo "INFO: Install plugins"
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$ADMIN_PASSWORD install-plugin git matrix-auth

# Set System Message via CLI
CRUMB=$(curl -u "admin:admin_password" -s 'http://localhost:8080/crumbIssuer/api/json' | jq -r '.crumb')
curl -X POST -u "admin:admin_password" http://localhost:8080/scriptText \
-H "Jenkins-Crumb: $CRUMB" \
--data-urlencode "script=Jenkins.instance.setSystemMessage('Jenkins Setup Complete')"

# Restart Jenkins to Apply Changes
systemctl restart jenkins