terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.35.0"
    }
  }

  backend "s3" {
    bucket = "trace-tf-unlocked-bucket"
    key    = "route53/aws-net-terraform.tfstate"
    region = "us-east-1"
    #dynamodb_table = "terraform_state"
  }
}

provider "aws" {
  region = var.region_aws
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "trace-tf-unlocked-bucket"
    key    = "network/aws-net-terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket = "trace-tf-unlocked-bucket"
    key    = "s3/aws-net-terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "acm" {

  backend = "s3"
  config = {
    bucket = "trace-tf-unlocked-bucket"
    key    = "acm/aws-net-terraform.tfstate"
    region = "us-east-1"
  }
}
