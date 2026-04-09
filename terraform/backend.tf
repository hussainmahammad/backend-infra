terraform {
  backend "s3" {
    bucket = "hsncloud-backend-state"
    key    = "backend-infra/terraform.tfstate"
    region = "us-east-1"
  }
}
