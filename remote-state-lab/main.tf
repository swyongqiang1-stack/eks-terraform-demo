
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
    region = "ap-southeast-1" 
}


resource "aws_s3_bucket" "stste_bucket" {
  bucket = "elden-state-bucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

