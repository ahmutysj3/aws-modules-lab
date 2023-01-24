######################################
### Cloudwatch VPC Flow Log Module ###
######################################

// TF Remote State Files //
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "trace-tf-unlocked-bucket"
    key    = "main/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

// Flow Log Actual //
resource "aws_flow_log" "main" {
  for_each        = data.terraform_remote_state.vpc.outputs.vpcs
  iam_role_arn    = aws_iam_role.main.arn
  log_destination = aws_cloudwatch_log_group.main.arn
  traffic_type    = "ALL"
  vpc_id          = each.value.id
}

// Flow Log Group //
resource "aws_cloudwatch_log_group" "main" {
  name = "main"
}

// IAM Role allowing access to logs //
resource "aws_iam_role" "main" {
  name = "main"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

// IAM Policy //
resource "aws_iam_role_policy" "main" {
  name = "main"
  role = aws_iam_role.main.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}