# Account C basic VPC only (provider aws.c)

resource "aws_vpc" "c_vpc" {
  provider = aws.c
  cidr_block = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "c-vpc" }
}

resource "aws_subnet" "c_pub" {
  provider = aws.c
  vpc_id = aws_vpc.c_vpc.id
  cidr_block = "10.2.1.0/24"
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true
  tags = { Name = "c-public-subnet" }
}

resource "aws_internet_gateway" "c_igw" {
  provider = aws.c
  vpc_id = aws_vpc.c_vpc.id
  tags = { Name = "c-igw" }
}

resource "aws_route_table" "c_rt" {
  provider = aws.c
  vpc_id = aws_vpc.c_vpc.id
  tags = { Name = "c-public-rt" }
}

resource "aws_route_table_association" "c_rta_pub" {
  provider = aws.c
  subnet_id = aws_subnet.c_pub.id
  route_table_id = aws_route_table.c_rt.id
}

resource "aws_route" "c_route_internet" {
  provider = aws.c
  route_table_id = aws_route_table.c_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.c_igw.id
}


resource "aws_iam_role" "account_c_role" {
  provider = aws.c
  name = "account-c-admin-for-account-a"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.a.account_id}:root"  # Account A ID
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "account_c_admin_attach" {
  provider = aws.c
  role       = aws_iam_role.account_c_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}