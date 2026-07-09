resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = aws_s3_bucket.stste_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}