variable "region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

# 🔐 AWS Credentials (for GitHub Actions)
variable "aws_a_access_key" {
  type        = string
  description = "Access key for Account A"
}

variable "aws_a_secret_key" {
  type        = string
  description = "Secret key for Account A"
}

variable "aws_b_access_key" {
  type        = string
  description = "Access key for Account B"
}

variable "aws_b_secret_key" {
  type        = string
  description = "Secret key for Account B"
}

variable "aws_c_access_key" {
  type        = string
  description = "Access key for Account C"
}

variable "aws_c_secret_key" {
  type        = string
  description = "Secret key for Account C"
}

# 🔑 SSH Public Key (from your generated backend-key.pub)
variable "public_key" {
  type        = string
  description = "Public SSH key content"
}

# 🔑 Key pair name in AWS
variable "key_name" {
  type    = string
  default = "backend-key"
}

# 🖥️ EC2 Config
variable "instance_ami" {
  type        = string
  description = "AMI id to use for EC2 (us-east-1). Replace before apply."
  default     = "ami-068c0051b15cdb816"
}

variable "instance_type" {
  type    = string
  default = "m7i-flex.large"
}