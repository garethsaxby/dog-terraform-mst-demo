package main

# Setting up resources
s3_bucket := input["resource.aws_s3_bucket.state_storage"]
dynamodb_table := input["resource.aws_dynamodb_table.state_lock"]
partial_state_file := input["resource.local_file.partial_state"]

# Basic tests for resources existing
deny[msg] {
  not s3_bucket
  msg := "State S3 Bucket should be defined."
}

deny[msg] {
  not dynamodb_table
  msg := "State Lock DynamoDB Table should be defined."
}

deny[msg] {
  not partial_state_file
  msg := "Local Partial State file should be defined."
}

# S3 Bucket Tests
deny[msg] {
  not s3_bucket.acl == "private"
  msg := "Canned ACL should be set to Private on the S3 Bucket."
}

deny[msg] {
  not s3_bucket.force_destroy == false
  msg := "Force Destroy should be disabled on the S3 Bucket."
}

deny[msg] {
  not s3_bucket.versioning.enabled == true
  msg := "Versioning should be enabled by default on the S3 bucket."
}

deny[msg] {
  not s3_bucket.versioning.mfa_delete == false
  msg := "MFA Delete should be disabled by default on the S3 bucket."
}

# DynamoDB Table Tests
deny[msg] {
  not dynamodb_table.billing_mode == "PAY_PER_REQUEST"
  msg := "Billing Mode should be set to PAY_PER_REQUEST on the DynamoDB table."
}

deny[msg] {
  not dynamodb_table.server_side_encryption.enabled == true
  msg := "Server Side Encrpytion should be enabled on the DynamoDB table."
}

deny[msg] {
  not dynamodb_table.point_in_time_recovery.enabled == false
  msg := "Point in Time Recovery should be disabled on the DynamoDB table."
}

deny[msg] {
  not dynamodb_table.hash_key == "LockID"
  msg := "Hash Key should be 'LockID' on the DynamoDB table."
}

# Partal State File Tests
deny[msg] {
  not partial_state_file.filename == "state.ini"
  msg := "Partial State Filename should be 'state.ini'"
}

deny[msg] {
  not partial_state_file.file_permission == "0644"
  msg := "Partial State File permissions should be 0644"
}
