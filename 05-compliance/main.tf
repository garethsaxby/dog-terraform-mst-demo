# This module is built against Terraform 0.12 or higher
terraform {
  required_version = ">= 0.12"
}

# Terraform State S3 Bucket
resource "aws_s3_bucket" "state_storage" {
  bucket = var.state_bucket_name

  # Set the canned ACL to private
  # https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl
  # Prevents any default access apart from the bucket owner (The AWS account containing the bucket)
  acl = "private"

  # Disable Force Destroy, meaning the state bucket cannot be destroyed without first emptying it
  # This should prevent any unintentional deletion of the bucket
  # We do not want to set the lifecycle to prevent deletion, as this breaks testing the full lifecycle of the module
  force_destroy = false

  # Enforce bucket encryption using AWS KMS
  # Terraform state should be encrypted at all times due to containing potentially sensitive data
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        # TODO: Allow for custom KMS key instead of AWS provided default
        sse_algorithm = "aws:kms"
      }
    }
  }

  # Enable bucket versioning by default to enable state recovery and historical change logging
  # Do not enable MFA delete as Terraform itself cannot enter an MFA code and may need to delete state files
  # Instead, we should seek to limit access to this bucket at all
  versioning {
    enabled    = true
    mfa_delete = false
  }

  # Enable lifecycle management for versioning
  # Necessary to reduce the overall long term spend, which will otherwise continue to increase
  lifecycle_rule {
    enabled = true

    # Push versions to Glacier after approximately three months of storage
    # TODO: Allow for custom length and disable
    noncurrent_version_transition {
      days          = 93
      storage_class = "GLACIER"
    }

    # Retain versions for approximately three years
    # TODO: Allow for custom length and disable
    noncurrent_version_expiration {
      days = 1095
    }
  }

  # TODO: Allow for extra tags to be added
  tags = {
    Name    = var.state_bucket_name
    Purpose = "Terraform State file storage bucket for S3 Backend - https://www.terraform.io/docs/backends/types/s3.html"
  }
}


# Terraform State Lock Table
resource "aws_dynamodb_table" "state_lock" {
  name = var.lock_table_name

  # On-Demand Capacity is used due to the low table throughput
  billing_mode = "PAY_PER_REQUEST"

  # This is a confusing option on the part of the Terraform provider
  # Encryption is -ALWAYS- enabled for the DynamoDB table regardless of setting
  # Instead, True sets to use an AWS Managed CMK instead of an AWS Owned CMK
  # https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html 
  # https://www.terraform.io/docs/providers/aws/r/dynamodb_table.html#server_side_encryption-1
  # AWS Managed CMK is used only within your own AWS account, key material controlled by AWS, pay per request
  # AWS Owned CMK is used across other AWS accounts, key material controlled by AWS, free requests
  # Customer Managed CMK is not available for DynamoDB as of 2020-01-03
  server_side_encryption {
    # TODO: Allow switching between AWS Owned/Managed CMK for cost saving
    enabled = true
  }

  # There is no point in enabling Point in Time recovery for the Lock table
  # Should the table be lost, then all locks can be recreated as required
  # Specifically disabled to save costs
  point_in_time_recovery {
    enabled = false
  }

  # Table Layout as per S3 Backend Requirements
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # TODO: Allow for extra tags to be added
  tags = {
    Name    = var.lock_table_name
    Purpose = "Terraform State lock table for S3 Backend - https://www.terraform.io/docs/backends/types/s3.html"
  }
}

# We are using a data object instead of the `file` function as the file does not exist on first run
# https://www.terraform.io/docs/configuration/functions/file.html
data "local_file" "partial_state_template" {
  filename = "${path.module}/state.tpl"
}

data "template_file" "partial_state" {
  template = data.local_file.partial_state_template.content

  vars = {
    bucket_name         = aws_s3_bucket.state_storage.id
    region_name         = aws_s3_bucket.state_storage.region
    dynamodb_table_name = aws_dynamodb_table.state_lock.id
    # kms_key_id     = aws_kms_key.state.arn
    # role_arn       = aws_iam_role.access.arn
  }
}

resource "local_file" "partial_state" {
  content = data.template_file.partial_state.rendered

  filename        = "state.ini"
  file_permission = "0644"
}

# Using the HashiCorp recomended aws_iam_policy_document data type for IAM policy composition
# https://learn.hashicorp.com/terraform/aws/iam-policy#choosing-a-configuration-method
data "aws_iam_policy_document" "state_access" {
  policy_id = "TerraformStateAccess"
  version   = "2012-10-17"

  # S3 Permissions are as per HashiCorp Specification:
  # https://www.terraform.io/docs/backends/types/s3.html#s3-bucket-permissions
  statement {
    sid    = "S3BucketAccess"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.state_storage.arn
    ]
  }

  statement {
    sid    = "S3BucketObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    # https://www.terraform.io/docs/configuration/functions/format.html
    resources = [
      format("%s/*", aws_s3_bucket.state_storage.arn)
    ]
  }

  # DynamoDB Permissions are as per HashiCorp Specification:
  # https://www.terraform.io/docs/backends/types/s3.html#dynamodb-table-permissions
  statement {
    sid    = "DynamodbAccess"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]

    resources = [
      aws_dynamodb_table.state_lock.arn
    ]
  }
}

resource "aws_iam_policy" "state_access" {
  name_prefix = "terraform-state-access"
  path        = "/"
  description = "Terraform State Access granting access to both the S3 State Storage Bucket and DynamoDB Lock Table."

  policy = data.aws_iam_policy_document.state_access.json
}
