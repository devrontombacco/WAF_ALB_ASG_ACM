

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "12.0.0.0/16"

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
