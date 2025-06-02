
output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}
