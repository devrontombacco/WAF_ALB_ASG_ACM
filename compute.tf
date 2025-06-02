
# Create Launch Template for Auto-Scaling Group
resource "aws_launch_template" "launch_template_for_asg" {
  name_prefix   = "my-template-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_name

  network_interfaces {
    security_groups = [aws_security_group.ec2-sg.id]
    associate_public_ip_address = true
  }

  # user_data = base64encode(file("user_data.sh"))
  user_data = base64encode(templatefile("user_data.sh", {}))
}

# # Create Auto-Scaling Group 
resource "aws_autoscaling_group" "asg_for_main_vpc" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.public_subnet1a.id, aws_subnet.public_subnet1b.id]
  target_group_arns    = [aws_lb_target_group.alb-tg.arn]

  launch_template {
    id      = aws_launch_template.launch_template_for_asg.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ASG-Instance"
    propagate_at_launch = true
  }

}


# Dynamically create Ubuntu AMI for EC2
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
