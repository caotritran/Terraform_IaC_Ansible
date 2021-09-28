terraform {
  required_version = ">=0.12.0"
  required_providers {
    aws = ">=3.0.0"
  }
  backend "s3" {
    region  = "us-east-1"
    profile = "terraform"
    key     = "terraformstatefile"
    bucket  = "terraformstate1994a"
  }
}
