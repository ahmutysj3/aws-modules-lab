resource "aws_s3_bucket" "website_hosting" {
  bucket = "trace-auto.ninja"

  tags = {
    Name = "trace-auto.ninja"
  }
}

resource "aws_s3_bucket" "website_redirect" {
  bucket = "www.trace-auto.ninja"

  tags = {
    Name = "www.trace-auto.ninja"
  }
}

resource "aws_s3_bucket" "website_logging" {
  bucket = "log.trace-auto.ninja"

  tags = {
    Name = "log.trace-auto.ninja"
  }
}

resource "aws_s3_bucket_acl" "website_hosting" {
  bucket = aws_s3_bucket.website_hosting.id
  acl    = "public-read"
}

resource "aws_s3_bucket_acl" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id
  acl    = "public-read"
}

resource "aws_s3_bucket_acl" "website_logging" {
  bucket = aws_s3_bucket.website_logging.id
  acl    = "private"
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.website_logging.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_logging" "website_hosting" {
  bucket = aws_s3_bucket.website_hosting.id

  target_bucket = aws_s3_bucket.website_logging.id
  target_prefix = "log/root/"
}

resource "aws_s3_bucket_logging" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id

  target_bucket = aws_s3_bucket.website_logging.id
  target_prefix = "log/www/"
}
resource "aws_kms_key" "website_logging" {
  description             = "This key is used to encrypt bucket objects in the website logging bucket"
  deletion_window_in_days = 7
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website_logging" {
  bucket = aws_s3_bucket.website_logging.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.website_logging.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "website_hosting" {
  bucket = aws_s3_bucket.website_hosting.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_public_access_block" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_hosting" {
  bucket = aws_s3_bucket.website_hosting.id
  policy = data.aws_iam_policy_document.website_hosting.json
}

resource "aws_s3_bucket_policy" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id
  policy = data.aws_iam_policy_document.website_redirect.json
}

data "aws_iam_policy_document" "website_hosting" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.website_hosting.id}/*"]
    effect    = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

data "aws_iam_policy_document" "website_redirect" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.website_redirect.id}/*"]
    effect    = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_versioning" "website_hosting" {
  bucket = aws_s3_bucket.website_hosting.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "website_redirect" {
  bucket = aws_s3_bucket.website_redirect.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website_hosting.id
  key          = "index.gif"
  source       = "./object/ooooohweeee.gif"
  etag         = filemd5("./object/ooooohweeee.gif")
  content_type = "image/gif"
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website_hosting.id
  key          = "error.gif"
  source       = "./object/ooooohweeee.gif"
  etag         = filemd5("./object/ooooohweeee.gif")
  content_type = "image/gif"
}

resource "aws_s3_bucket_website_configuration" "website_hosting" {
  bucket = aws_s3_bucket.website_hosting.bucket

  index_document {
    suffix = "index.gif"
  }

  error_document {
    key = "error.gif"
  }
}

resource "aws_s3_bucket_website_configuration" "website_redirect" {
  depends_on = [
    aws_s3_bucket.website_hosting
  ]
  bucket = aws_s3_bucket.website_redirect.bucket
  redirect_all_requests_to {
    host_name = aws_s3_bucket.website_hosting.bucket
    protocol  = "http"
  }
}

output "s3_website" {
  value = {
    website_bucket  = aws_s3_bucket.website_hosting.id
    redirect_bucket = aws_s3_bucket.website_redirect.id
    log_bucket_id   = aws_s3_bucket.website_logging.id
    www_arn         = aws_s3_bucket.website_redirect.arn
    root_art        = aws_s3_bucket.website_hosting.arn
    url             = "http://${aws_s3_bucket.website_hosting.bucket}.s3-website-${var.region_aws}.amazonaws.com"
    www             = "http://${aws_s3_bucket.website_redirect.bucket}.s3-website-${var.region_aws}.amazonaws.com"
  }
}

output "hosting_bucket" {
  value = aws_s3_bucket.website_hosting
}

output "redirect_bucket" {
  value = aws_s3_bucket.website_redirect
}

