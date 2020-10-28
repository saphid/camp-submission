provider "aws" {
  region = "us-east-2"
}

# terraform {
#   backend "s3" {
#     bucket = go-webserver-demo"
#     key    = "global/s3/terraform.tfstate"
#     region = "us-east-2"

#     dynamodb_table = "terraform_state_locks"
#     encrypt        = true
#   }
# }

resource "aws_s3_bucket" "terraform_state" {
  bucket = "go-webserver-demo-alxs001"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "staging_terraform_locks" {
  name         = "terraform_staging_state_locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "prod_terraform_locks" {
  name         = "terraform_prod_state_locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" {
    value = aws_s3_bucket.terraform_state.arn
    description = "The ARN of the state S3 bucket"
}

output "dynamodb_prod_table_name" {
    value = aws_dynamodb_table.prod_terraform_locks.name
    description = "The name of the dynamoDB table"
}


output "dynamodb_staging_table_name" {
    value = aws_dynamodb_table.staging_terraform_locks.name
    description = "The name of the dynamoDB table"
}