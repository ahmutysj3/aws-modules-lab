resource "aws_s3_bucket" "tf-bucket-locked" {
  bucket              = "trace-tf-locked-bucket"
  object_lock_enabled = true
}

resource "aws_s3_bucket" "tf-bucket-unlocked" {
  bucket              = "trace-tf-unlocked-bucket"
  object_lock_enabled = false
}

locals {
  tf_s3_lock = aws_s3_bucket.tf-bucket-locked.arn
}

locals {
  tf_s3_unlock = aws_s3_bucket.tf-bucket-unlocked.arn
}

resource "aws_s3_bucket_versioning" "terraform-locked" {
  bucket = aws_s3_bucket.tf-bucket-locked.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "terraform-unlocked" {
  bucket = aws_s3_bucket.tf-bucket-unlocked.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "terraform" {
  description             = "This key is used to encrypt bucket objects used in terraform lab"
  deletion_window_in_days = 30
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform-locked" {
  bucket = aws_s3_bucket.tf-bucket-locked.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform-unlocked" {
  bucket = aws_s3_bucket.tf-bucket-unlocked.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_dynamodb_table" "terraform-lock" {
  name           = "terraform_state"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    "Name" = "DynamoDB Terraform State Lock Table"
  }
}

resource "aws_s3_bucket_policy" "terraform-locked" {
  bucket = aws_s3_bucket.tf-bucket-locked.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.user_arn}"
      },
      "Action": [ "s3:*" ],
      "Resource": [
        "${local.tf_s3_lock}",
        "${local.tf_s3_lock}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_s3_bucket_policy" "terraform-unlocked" {
  bucket = aws_s3_bucket.tf-bucket-unlocked.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.user_arn}"
      },
      "Action": [ "s3:*" ],
      "Resource": [
        "${local.tf_s3_unlock}",
        "${local.tf_s3_unlock}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_s3_bucket_object_lock_configuration" "terraform" {
  bucket = aws_s3_bucket.tf-bucket-locked.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 7
    }
  }
}



