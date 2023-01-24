terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.39.0"
    }
  }
/*   backend "s3" {
    bucket         = "tf-bucket-unlocked"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    #dynamodb_table = "terraform_state"
  } */
}

provider "aws" {
  region = var.aws_region
}

