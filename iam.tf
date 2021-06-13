# current user info 
data "aws_caller_identity" "current" {}

locals {
  # allowed accounts
  principal_arns = var.principal_arns != null ? var.principal_arns : [data.aws_caller_identity.current.arn]
}

# role to assume in order to use s3 bucket
resource "aws_iam_role" "role" {
  name = "${local.namespace}-tf-assume-role"

  # sts - security token service
  assume_role_policy = <<-EOF
    { 
      "Version": "2012-10-17", 
         "Statement": [ 
        { 
          "Action": "sts:AssumeRole", 
          "Principal": { 
              "AWS": ${jsonencode(local.principal_arns)} 
          }, 
          "Effect": "Allow" 
        } 
      ] 
    } 
    EOF

  tags = {
    "ResourceGroup" = local.namespace
  }
}

# standalone policy in HCL lang instead of in-line json
data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.bucket.arn
    ]
  }

  statement {
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]

    # CRUD bucket files
    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }

  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [aws_dynamodb_table.table.arn]
  }
}

# supports in-line policy 
resource "aws_iam_policy" "policy" {
  name   = "${local.namespace}-tf-policy"
  path = "/"
  policy = data.aws_iam_policy_document.policy.json
}

# attach policy to the role
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
