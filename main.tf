

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

# Create EC2 instance in subnet 1a
resource "aws_instance" "ec2_instance_1a" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = "eu-west-1a"
  subnet_id         = aws_subnet.public_subnet1a.id
  key_name          = "MY_EC2_INSTANCE_KEYPAIR"

  tags = {
    Name = "ec2_instance_1a"
  }
  vpc_security_group_ids = [aws_security_group.ec2-sg-ssh-http.id]

  user_data = <<-EOF
  #!/bin/bash
  yes | sudo apt update 
  yes | sudo apt install apache2
  echo "<h1>Server Details</h1><p><strong>Hostname:</strong> $(hostname)</p><p><strong>IP Address:</strong>$(hostname -I | cut -d" " -f1)</strong></p>"> /var/www/html/index.html
  sudo systemctl restart apache2
  EOF 

}

# Create EC2 instance in subnet 1b
resource "aws_instance" "ec2_instance_1b" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  availability_zone = var.availability_zone_1b
  subnet_id         = aws_subnet.public_subnet1b.id
  key_name          = var.key_name

  tags = {
    Name = "ec2_instance_1b"
  }
  vpc_security_group_ids = [aws_security_group.ec2-sg-ssh-http.id]

  user_data = <<-EOF
  #!/bin/bash
  yes | sudo apt update 
  yes | sudo apt install apache2
  echo "<h1>Server Details</h1><p><strong>Hostname:</strong> $(hostname)</p><p><strong>IP Address:</strong>$(hostname -I | cut -d" " -f1)</strong></p>"> /var/www/html/index.html
  sudo systemctl restart apache2
  EOF 

}

#Create env var for my ip address 

variable "my_ip_address" {
  type    = string
  default = "0.0.0.0/0" # fallback IP
}

# Create security groups for EC2 instances

resource "aws_security_group" "ec2-sg-ssh-http" {
  name        = "public_ec2_sg"
  description = "Allow inbound traffic on ports 22 and 80"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

  ingress {
    description = "allow http traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Groups for ALB 

resource "aws_security_group" "alb_sg_ssh" {
  name        = "alb-sg"
  description = "Allow HTTP from the world"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

# Register EC2 instances in TG 
resource "aws_lb_target_group_attachment" "alb_tg_attachment_1a" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.ec2_instance_1a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "alb_tg_attachment_1b" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.ec2_instance_1b.id
  port             = 80
}

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg_ssh.id]
  subnets            = [
    aws_subnet.public_subnet1a.id,
    aws_subnet.public_subnet1b.id
  ]

  tags = {
    Name = "app-alb"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}
