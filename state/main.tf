provider "aws" {
  region = var.region-1
}

provider "aws" {
  alias  = "region-2"
  region = var.region-2
}

resource "aws_s3_bucket" "terraform_state" {
  count = var.create_bucket? 1 : 0
  bucket = var.terraform_state_bucket
  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "region-1" {
  count = var.create_lock_table? 1 : 0
  provider = aws

  name         = var.dynamodb_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "region-2" {
  count = var.create_lock_table? 1 : 0
  provider = aws.region-2

  name         = var.dynamodb_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_dynamodb_global_table" "vernon-terraform-locks" {
  count = var.create_lock_table? 1 : 0
  depends_on = [aws_dynamodb_table.region-1, aws_dynamodb_table.region-2]
  provider   = aws

  name = var.dynamodb_lock_table_name

  replica {
    region_name = var.region-1
  }

  replica {
    region_name = var.region-2
  }
}
