
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


#Create ALB
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