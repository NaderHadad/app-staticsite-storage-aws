# RESOURCE: S3 BUCKET (INFRA)

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "bucket-versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_iam_role" "terraform_execution_role" {
  name = "terraform_execution_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"  # Ou qualquer serviço que precise assumir a função
        }
      }
    ]
  })

  # Outras configurações do role, se necessário
}
resource "aws_iam_policy" "s3_acl_policy" {
  name        = "s3_acl_policy"
  description = "Policy for modifying S3 ACLs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutBucketAcl",
          "s3:PutObjectAcl",
        ],
        Effect   = "Allow",
        Resource = [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*",
        ],
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "s3_acl_attachment" {
  policy_arn = aws_iam_policy.s3_acl_policy.arn
  role       = aws_iam_role.terraform_execution_role.name
}

resource "aws_s3_bucket_acl" "bucket-acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
  
}

resource "aws_s3_bucket_website_configuration" "bucket-website-configuration" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

output "aws_s3_bucket_website_endpoint" {
  value = "http://${var.website_endpoint == "true" ? aws_s3_bucket_website_configuration.bucket-website-configuration.website_endpoint : ""}"
}


# RESOURCE: S3 BUCKET OBJECTS (APPLICATION)

resource "aws_s3_object" "bucket-objects" {
  bucket       = aws_s3_bucket.bucket.id
  for_each     = fileset("../app/", "*")
  key          = each.value
  source       = "../app/${each.value}"
  acl          = "public-read"
  content_type = "text/html"
  etag         = md5(file("../app/${each.value}"))
}