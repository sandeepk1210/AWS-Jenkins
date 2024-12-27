resource "aws_launch_template" "jenkins_lt" {
  name          = "jenkins-launch-template"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = var.instance_type

  network_interfaces {
    device_index                = 0
    subnet_id                   = data.aws_subnet.default_subnet.id
    security_groups             = [aws_security_group.jenkins_sg.id]
    associate_public_ip_address = true
  }

  user_data = filebase64("${path.module}/setup-jenkins.sh")
}

resource "aws_autoscaling_group" "jenkins_asg" {
  launch_template {
    id      = aws_launch_template.jenkins_lt.id
    version = aws_launch_template.jenkins_lt.latest_version
  }
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [data.aws_subnet.default_subnet.id]
}
