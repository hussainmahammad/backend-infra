# Account B resources (provider aws.b)

resource "aws_vpc" "b_vpc" {
  provider = aws.b
  cidr_block = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "b-vpc" }
}

resource "aws_subnet" "b_pub" {
  provider = aws.b
  vpc_id = aws_vpc.b_vpc.id
  cidr_block = "10.1.1.0/24"
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true
  tags = { Name = "b-public-subnet" }
}

resource "aws_internet_gateway" "b_igw" {
  provider = aws.b
  vpc_id = aws_vpc.b_vpc.id
  tags = { Name = "b-igw" }
}

resource "aws_route_table" "b_rt" {
  provider = aws.b
  vpc_id = aws_vpc.b_vpc.id
  tags = { Name = "b-public-rt" }
}

resource "aws_route_table_association" "b_rta_pub" {
  provider = aws.b
  subnet_id = aws_subnet.b_pub.id
  route_table_id = aws_route_table.b_rt.id
}

resource "aws_route" "b_route_internet" {
  provider = aws.b
  route_table_id = aws_route_table.b_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.b_igw.id
}

# Keypair import
resource "aws_key_pair" "b_key" {
  provider   = aws.b
  key_name   = var.key_name
  public_key = var.public_key   # ✅ FIXED
}

# Security Group for Jenkins Agent
resource "aws_security_group" "jenkins_agent_sg" {
  provider = aws.b
  name   = "jenkins-agent-sg"
  vpc_id = aws_vpc.b_vpc.id
  description = "SG for Jenkins Agent / Build Node"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    # allow JNLP from Jenkins Master VPC
    cidr_blocks = ["10.0.0.0/16","10.2.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jenkins-agent-sg" }
}

# EC2 Build Node
resource "aws_instance" "build_node" {
  provider = aws.b
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.b_pub.id
  vpc_security_group_ids = [aws_security_group.jenkins_agent_sg.id]
  key_name      = aws_key_pair.b_key.key_name
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }
  associate_public_ip_address = true
  tags = {
    Name = "build-node-b"
    Role = "jenkins-agent"
    Env  = "dev"
  }
}

# Route from Account B VPC to Account A VPC via peering
resource "aws_route" "b_to_a_peering" {
  provider                  = aws.b
  route_table_id             = aws_route_table.b_rt.id
  destination_cidr_block     = "10.0.0.0/16"
  vpc_peering_connection_id  = aws_vpc_peering_connection.a_b.id
}