output "state_storage_bucket" {
  value       = aws_s3_bucket.state_storage
  description = "The S3 bucket created for storing the Terraform state."
}

output "state_lock_table" {
  value       = aws_dynamodb_table.state_lock
  description = "The DynamoDB table created for locking the Terraform state."
}
