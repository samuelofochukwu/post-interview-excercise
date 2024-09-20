provider "aws" {
  region = "us-west-2"
}

# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "PrivateVPC"
  }
}

# Create Private Subnet

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "PrivateSubnet"
  }
}

# Private Route Tables, , which routes all non-local traffic to the Transit Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  # Route all DNS traffic (non-local) to the provided DNS resolvers via Transit Gateway
  route {
    destination_prefix_list_id = "0.0.0.0/0"
    transit_gateway_id         = "tgw-00aaaa000011112222"
  }
}


# Associate route tables with private subnet
resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group allowing HTTPS and DNS traffic
resource "aws_security_group" "main_sg" {
  vpc_id = aws_vpc.main_vpc.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow DNS Queries to internal resolvers via Transit Gateway
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.2.3.0/24", "10.2.4.0/24"] # IPs for the recursive DNS resolvers
  }
}

# Launch an EC2 instance inside the VPC (in the private subnet)
resource "aws_instance" "web_instance" {
  ami             = "ami-08d8ac128e0a1b91c"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.main_sg.name]

  tags = {
    Name = "WebServer"
  }
}

# Transit Gateway Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  transit_gateway_id = "tgw-00aaaa000011112222"
  vpc_id             = aws_vpc.main_vpc.id
  subnet_ids         = [aws_subnet.private_subnet.id]

  tags = {
    Name = "TGWAttachment"
  }
}