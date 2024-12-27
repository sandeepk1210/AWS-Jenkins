# Purpose

Creating a new Jenkin instance on EC2 machine in AWS

- Using Terraform to create EC2 instance in AWS
- Creating EC2 instance which is access by Public IP
- For high availability, using Auto Scaling to always have 1 EC2 instance
- Installed Jenkins on the EC2 instance
- Creating a sample job in Jenkins
- Access Jenkins:
  - URL: http://<server-ip>:8080
  - Username: admin
  - Password: admin
- Verify the Sample Job:
  - Log in to Jenkins.
  - Check if the job sample-job exists.
  - Run the pipeline manually to verify.

## Usage

1. **Install Terraform**: Ensure you have Terraform installed on your machine. If not, download it from [terraform.io](https://www.terraform.io/downloads.html).

2. Clone this repository:

   ```bash
   git clone <repository-url>
   cd <repository-name>
   ```

3. **Set Up AWS Provider**

- Machine from which this terraform is running, either

  - have relevant IAM role OR
  - Export following as environment variables

    ```bash
    export AWS_DEFAULT_REGION=us-east-1
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
    ```

4. **Initialize Terraform**: Run the following command to initialize your Terraform workspace:

   ```bash
   terraform init
   ```

5. **Plan the Deployment**: To see the changes that will be made, run:

   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

6. **Apply the Configuration**: Deploy the resources with:

   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

## Steps:

1. Terraform Configuration for EC2 Instance:

- Define the AWS provider and credentials.

- Create a VPC, subnet, security group, and IAM role.

- Configure the EC2 instance resource.

2. Public Accessibility:

- Assign a public IP to the EC2 instance.

- Configure the security group to allow inbound access on port 22 (SSH) and port 8080 (Jenkins UI).

3. Auto Scaling Group:

- Define an Auto Scaling Group to ensure at least one EC2 instance is always running.

- Set up a Launch Template for the EC2 instance.

4. Jenkins Installation:

- Use a user data script to install Jenkins during EC2 instance boot-up.

- Start and enable the Jenkins service.

- User Account & Security

  - Creates **admin** user with **admin_password**.
  - Configures **FullControlOnceLoggedInAuthorizationStrategy** to restrict anonymous access.

- Sample Job Creation

  - Creates a Jenkins pipeline job named **sample-job**.
  - Includes **Build**, **Test**, and **Deploy** stages.
  - Runs a sample **pipeline script**.

- Plugin Installation

  - Installs plugins: **git**, **matrix-auth**, and **job-dsl** for Jenkins.

- System Message

  - Displays a system message in Jenkins: **"Jenkins Setup Complete with Sample Job"**.

- File Permissions & Restart
  - Ensures correct **ownership** and restarts **Jenkins** for changes to apply.

5. Access Jenkins:

- Access Jenkins via http://<<public-ip of instance>>:8080

## Troubleshooting:

## 1. Verify EC2 `user_data` Execution

### Check Cloud-Init Logs

Cloud-init handles the execution of your `user_data` script. If something failed, it will be logged.

```bash
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
```

## 2. Verify Jenkins Installation

### Check Jenkins Service Status

Ensure Jenkins started correctly:

```bash
sudo systemctl status jenkins
sudo journalctl -u jenkins
```
Look for errors related to Java, ports, or permission issues.

### Check Jenkins Logs

Jenkins logs provide insight into why it might have failed to initialize:

```bash
sudo cat /var/log/jenkins/jenkins.log
```
Look for exceptions or errors during startup.

