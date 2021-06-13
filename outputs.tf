output "config" {
  # required by official S3 backend
  # https://www.terraform.io/docs/language/settings/backends/s3.html
  value = {
    bucket         = aws_s3_bucket.bucket.bucket
    region         = data.aws_region.current.region
    role_arn       = aws_iam_role.role.arn
    dynamodb_table = aws_dynamodb_table.table.name
  }
}
