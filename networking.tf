
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