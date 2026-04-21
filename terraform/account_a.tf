# Account A resources (provider aws.a)

resource "aws_vpc" "a_vpc" {
  provider = aws.a
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "a-vpc" }
}

resource "aws_subnet" "a_pub" {
  provider = aws.a
  vpc_id = aws_vpc.a_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true
  tags = { Name = "a-public-subnet" }
}

resource "aws_internet_gateway" "a_igw" {
  provider = aws.a
  vpc_id = aws_vpc.a_vpc.id
  tags = { Name = "a-igw" }
}

resource "aws_route_table" "a_rt" {
  provider = aws.a
  vpc_id = aws_vpc.a_vpc.id
  tags = { Name = "a-public-rt" }
}

resource "aws_route_table_association" "a_rta_pub" {
  provider = aws.a
  subnet_id = aws_subnet.a_pub.id
  route_table_id = aws_route_table.a_rt.id
}

resource "aws_route" "a_route_internet" {
  provider = aws.a
  route_table_id = aws_route_table.a_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.a_igw.id
}

# Key pair import
resource "aws_key_pair" "a_key" {
  provider   = aws.a
  key_name   = var.key_name
  public_key = var.public_key   # ✅ FIXED
}

# Security Group for Jenkins Master
resource "aws_security_group" "jenkins_master_sg" {
  provider = aws.a
  name   = "jenkins-master-sg"
  vpc_id = aws_vpc.a_vpc.id
  description = "SG for Jenkins Master"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16","10.2.0.0/16"]
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
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jenkins-master-sg" }
}

# EC2 Jenkins Master
resource "aws_instance" "jenkins_master" {
  provider = aws.a
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.a_pub.id
  vpc_security_group_ids = [aws_security_group.jenkins_master_sg.id]
  key_name      = aws_key_pair.a_key.key_name
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
  tags = {
    Name = "jenkins-master-a"
    Role = "jenkins-master"
    Env  = "dev"
  }
}

# Route from Account A VPC to Account B VPC via peering
resource "aws_route" "a_to_b_peering" {
  provider                  = aws.a
  route_table_id             = aws_route_table.a_rt.id
  destination_cidr_block     = "10.1.0.0/16"
  vpc_peering_connection_id  = aws_vpc_peering_connection.a_b.id
}

# IAM Role for Jenkins EC2
resource "aws_iam_role" "jenkins_role" {
  provider = aws.a
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "jenkins_policy" {
  provider = aws.a
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*",
          "sts:AssumeRole"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  provider = aws.a
  role = aws_iam_role.jenkins_role.name
}

resource "aws_dynamodb_table" "applications" {
  provider = aws.a
  name     = "Applications"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "appId"

  attribute {
    name = "appId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "deployments" {
  provider = aws.a
  name     = "Deployments"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "deploymentId"

  attribute {
    name = "deploymentId"
    type = "S"
  }
}


# ===============================
# DynamoDB Application Seed Data
# ===============================

resource "aws_dynamodb_table_item" "app_hm001" {
  provider   = aws.a
  table_name = aws_dynamodb_table.applications.name
  hash_key   = "appId"

  item = jsonencode({
    appId              = "HM001"
    appName            = "petcart"
    createdAt          = "2025-01-18T10:00:00Z"
    deployJobName      = "deploy-petcart"
    destroyJobName     = "destroy-petcart"
    ec2Support         = true
    eksEc2Support      = true
    eksFargateSupport  = true
    genericSupport     = false
  })
}

resource "aws_dynamodb_table_item" "app_hm002" {
  provider   = aws.a
  table_name = aws_dynamodb_table.applications.name
  hash_key   = "appId"

  item = jsonencode({
    appId              = "HM002"
    appName            = "admin-petcart"
    createdAt          = "2025-02-28T11:00:00Z"
    deployJobName      = "deploy-admin-petcart"
    destroyJobName     = "destroy-admin-petcart"
    ec2Support         = true
    eksEc2Support      = true
    eksFargateSupport  = true
    genericSupport     = false
  })
}

resource "aws_dynamodb_table_item" "app_hm004" {
  provider   = aws.a
  table_name = aws_dynamodb_table.applications.name
  hash_key   = "appId"

  item = jsonencode({
    appId              = "HM004"
    appName            = "pdf-tools"
    createdAt          = "2026-02-22T11:00:00Z"
    deployJobName      = "deploy-pdf-tools"
    destroyJobName     = "destroy-pdf-tools"
    ec2Support         = false
    eksEc2Support      = false
    eksFargateSupport  = false
    genericSupport     = true
  })
}

resource "aws_dynamodb_table_item" "app_hm007" {
  provider   = aws.a
  table_name = aws_dynamodb_table.applications.name
  hash_key   = "appId"

  item = jsonencode({
    appId              = "HM007"
    appName            = "weblancehub"
    createdAt          = "2025-02-25T11:00:00Z"
    deployJobName      = "deploy-weblancehub"
    destroyJobName     = "destroy-weblancehub"
    ec2Support         = true
    eksEc2Support      = true
    eksFargateSupport  = true
    genericSupport     = false
  })
}
