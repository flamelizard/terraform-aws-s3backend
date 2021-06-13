data "aws_region" "current" {
}

resource "random_string" "rand" {
  length  = 24
  special = false
  upper   = false
}

locals {
  namespace = substr(join("-", [var.namespace, random_string.rand.result]), 0, 24)
}

# create AWS resource group by filtering existing resources
resource "aws_resourcegroups_group" "rg" {
  name = "${local.namespace}-group"
  resource_query {
    query = <<-JSON
    { 
        "ResourceTypeFilters": [ 
            "AWS::AllSupported" 
        ], 
        "TagFilters": [ 
            { 
            "Key": "ResourceGroup", 
            "Values": ["${local.namespace}"] 
            } 
        ] 
    } 
    JSON
  }
}

# encrypt bucket data
resource "aws_kms_key" "kms_key" {
  tags = {
    "ResourceGroup" = local.namespace
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket        = "${local.namespace}-state-bucket"
  force_destroy = var.force_destroy_state

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.kms_key.arn
      }
    }
  }

  tags = {
    "ResourceGroup" = local.namespace
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# no-sql managed DB
# state-locking to prevent multiple access
resource "aws_dynamodb_table" "table" {
  name         = "${local.namespace}-state-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST" # serverless
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    "ResourceGroup" = local.namespace
  }
}
