data "aws_availability_zones" "av_az" {}


resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr

    tags = {
      "Name" = "${var.env}-My VPC"
      "Environment" = "${var.env}"
    }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

      tags = {
      "Name" = "${var.env}-igw"
      "Environment" = "${var.env}"
    }
}

resource "aws_subnet" "public_subnets" {
  
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.av_az.names[count.index]
  map_public_ip_on_launch = true

      tags = {
      "Name" = "${var.env}-Public-Subnet-${count.index + 1}"
      "Environment" = "${var.env}"
    }
}

resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
      tags = {
      "Name" = "${var.env}-Route-Public-Subnets"
      "Environment" = "${var.env}"
    }
}

resource "aws_route_table_association" "public_subnets" {

  count = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
}


#===========================================
# EIP + NAT

resource "aws_eip" "nat" {
  count = length(var.private_subnet_cidrs)
  vpc = true
  tags = {
    "Name" = "${var.env}-nat-eip-${count.index+1}"
  }
  
}

resource "aws_nat_gateway" "nat" {
  count = length(var.private_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)

    tags = {
    "Name" = "${var.env}-nat-${count.index+1}"
  }
}

#===========================================
# PRIVATE SUBNETS

resource "aws_subnet" "private_subnets" {
  
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.av_az.names[count.index]

      tags = {
      "Name" = "${var.env}-Private-Subnet-${count.index + 1}"
      "Environment" = "${var.env}"
    }
}

resource "aws_route_table" "private_subnets" {

  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[count.index].id
  }
      tags = {
      "Name" = "${var.env}-Route-Private-Subnets"
      "Environment" = "${var.env}"
    }
}

resource "aws_route_table_association" "private_subnets" {

  count = length(aws_subnet.private_subnets[*].id)
  route_table_id = aws_route_table.private_subnets[count.index].id
  subnet_id = element(aws_subnet.private_subnets[*].id, count.index)
}
