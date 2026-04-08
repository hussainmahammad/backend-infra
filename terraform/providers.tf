terraform {
  required_providers {
    aws  = { source = "hashicorp/aws",  version = ">= 4.0" }
    time = { source = "hashicorp/time", version = ">= 0.7.0" }
  }
  required_version = ">= 1.0"
}

# 🅰️ Account A (Jenkins + Backend)
provider "aws" {
  alias      = "a"
  region     = var.region
  access_key = var.aws_a_access_key
  secret_key = var.aws_a_secret_key
}

# 🅱️ Account B (Agent)
provider "aws" {
  alias      = "b"
  region     = var.region
  access_key = var.aws_b_access_key
  secret_key = var.aws_b_secret_key
}

# 🅲 Account C (Target Infra)
provider "aws" {
  alias      = "c"
  region     = var.region
  access_key = var.aws_c_access_key
  secret_key = var.aws_c_secret_key
}

# ⏱️ Time provider (for delays)
provider "time" {}