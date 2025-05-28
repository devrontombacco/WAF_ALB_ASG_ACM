

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

   tags = {
    Name = "main_vpc"
  }
}


# Create Internet Gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "igw"
  }
}

# Create 1st public subnet
resource "aws_subnet" "public_subnet1a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet1a_cidr
  availability_zone       = var.availability_zone_1a
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet1a"
  }
}

# Create 2nd public subnet
resource "aws_subnet" "public_subnet1b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet1b_cidr
  availability_zone       = var.availability_zone_1b
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet1b"
  }
}

# Create 1 Route Table for both Public Subnets
resource "aws_route_table" "route_table_for_subnets" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "route-table-for-subnets"
  }

}

# Associate Route Table with Public Subnet 1a
resource "aws_route_table_association" "route_table_association_1a" {

  subnet_id      = aws_subnet.public_subnet1a.id
  route_table_id = aws_route_table.route_table_for_subnets.id

}

# Associate Route Table with Public Subnet 1b
resource "aws_route_table_association" "route_table_association_1b" {

  subnet_id      = aws_subnet.public_subnet1b.id
  route_table_id = aws_route_table.route_table_for_subnets.id

}

# Insert Route into route table
resource "aws_route" "internet_access_route" {
    
  route_table_id         = aws_route_table.route_table_for_subnets.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

}


# Create Target Group

resource "aws_lb_target_group" "alb-tg" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

# Create Security Groups for ALB 

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP from the world"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow http from anywhere
  }

   ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow https from anywhere
  }

   ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow ssh from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.public_subnet1a.id,
    aws_subnet.public_subnet1b.id
  ]

  tags = {
    Name = "app-alb"
  }
}

# Create ALB listener

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}

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

#Create env var for my ip address 

variable "my_ip_address" {
  type    = string
  default = "0.0.0.0/0" # fallback IP
}

# Create security groups for EC2 instances

resource "aws_security_group" "ec2-sg" {
  name        = "ec2_sg"
  description = "Allow inbound traffic on ports 22, 80 & 443"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address] #SSH for main admin only
  }

  ingress {
    description = "allow http traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id] #Only allow access from ALB
  }

  ingress {
    description = "allow https traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id] #Only allow access from ALB

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create IPSET

resource "aws_wafv2_ip_set" "my_ipSet" {
  name               = "my_ipSet"
  scope              = "REGIONAL" # For ALBs
  ip_address_version = "IPV4"

  addresses          = [var.my_ip]
  
  tags = {
    Environment = "Prod"
  }
}

# Rule for WAF
resource "aws_wafv2_web_acl" "web-acl" {
  name        = "app-WAF"
  scope       = "REGIONAL"
  description = "WAF with IPSet rule"
  
  default_action {
    allow {}
  }

  rule {
    name     = "allow-my-ip"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.my_ipSet.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "allow-my-ip"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = "app-waf"
  }
}

# WAF-ALB association 

resource "aws_wafv2_web_acl_association" "waf-alb-association" {
  resource_arn = aws_lb.app_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.web-acl.arn
}