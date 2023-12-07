# RESOURCE: S3 BUCKET (INFRA)

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  acl = "public-read"  # Configuração da ACL para permitir leitura pública
}

resource "aws_s3_bucket_versioning" "bucket-versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
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
