
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