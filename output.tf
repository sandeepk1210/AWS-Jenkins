# Output for the Launch Template
output "jenkins_launch_template_id" {
  description = "The ID of the Jenkins launch template"
  value       = aws_launch_template.jenkins_lt.id
}

output "jenkins_launch_template_latest_version" {
  description = "The latest version of the Jenkins launch template"
  value       = aws_launch_template.jenkins_lt.latest_version
}

# Output for the Auto Scaling Group
output "jenkins_asg_name" {
  description = "The name of the Jenkins Auto Scaling Group"
  value       = aws_autoscaling_group.jenkins_asg.name
}

output "jenkins_asg_desired_capacity" {
  description = "The desired capacity of the Jenkins Auto Scaling Group"
  value       = aws_autoscaling_group.jenkins_asg.desired_capacity
}

output "jenkins_asg_arn" {
  description = "The ARN of the Jenkins Auto Scaling Group"
  value       = aws_autoscaling_group.jenkins_asg.arn
}
