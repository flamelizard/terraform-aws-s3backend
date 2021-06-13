output "config" {
  value = {
    bucket         = aws_s3_bucket.bucket.bucket
    region         = aws_region.current.region
    role_arn       = aws_iam_role.role.arn
    dynamodb_table = aws_dynamodb_table.table.name
  }
}
