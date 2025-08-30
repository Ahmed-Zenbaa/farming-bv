resource "aws_s3_bucket" "nginx_assets" {
  bucket = "farming-bv-nginx-assets-${random_string.suffix.result}"

  tags = {
    Name = "farming-bv-nginx-assets"
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Enforce bucket ownership (no ACLs)
resource "aws_s3_bucket_ownership_controls" "nginx_assets" {
  bucket = aws_s3_bucket.nginx_assets.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "nginx_assets" {
  bucket                  = aws_s3_bucket.nginx_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload nginx.conf
resource "aws_s3_object" "nginx_conf" {
  bucket = aws_s3_bucket.nginx_assets.bucket
  key    = "nginx.conf"
  source = "${path.module}/files/nginx.conf"
  etag   = filemd5("${path.module}/files/nginx.conf")
}

# Upload image (logo.png)
resource "aws_s3_object" "logo" {
  bucket = aws_s3_bucket.nginx_assets.bucket
  key    = "farming-bv.jpg"
  source = "${path.module}/files/farming-bv.jpg"
  etag   = filemd5("${path.module}/files/farming-bv.jpg")
}

# Bucket policy allowing only the EC2 IAM role to read
data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.nginx_assets.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ssm_role.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_ec2" {
  bucket = aws_s3_bucket.nginx_assets.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}
