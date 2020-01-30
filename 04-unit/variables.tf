variable "state_bucket_name" {
  type        = string
  description = "The name for the Terraform state S3 bucket that will be created. Must be globally unique."
}

variable "lock_table_name" {
  type        = string
  description = "The name for the Terraform Locking DynamoDB table that will be created. Must be unique in the region of the AWS account it is created within."
}
