
variable "vpc_cidr" {
  description = "VPC's CIDR block"
  type = string
}

variable "public_subnet1a_cidr" {
  description = "CIDR block of subnet 1a"
  type = string
}

variable "public_subnet1b_cidr" {
  description = "CIDR block of subnet 1b"
  type = string
}

variable "availability_zone_1a" {
    description = "AZ of subnet 1a"
    type = string
}

variable "availability_zone_1b" {
    description = "AZ of subnet 1b"
    type = string
}

variable "instance_type" {
  description = "type of EC2 instance"
  type = string
}

variable "key_name" {
  description = "Name of keypair"
    type = string
}

variable "alb_target_group_name" {
  description = "Name of the ALB target group"
  type        = string
}

variable "my_ip" {
  description = "My IP"
  type        = string
}

#Create env var for my ip address 
variable "my_ip_address" {
  type    = string
  default = "0.0.0.0/0" # fallback IP
}