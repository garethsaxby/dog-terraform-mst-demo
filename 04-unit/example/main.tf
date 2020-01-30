provider "aws" {
  # We want to define where to deploy the code via the example
  region = "eu-west-1"
}

module "state_storage" {
  # Update your source parameter to point to the location of the module
  source = "../"

  # Naming the DynamoDB and S3 resources created by the module
  # Names should match the AWS naming requirements for S3 buckets and DynamoDB Tables
  # DynamoDB - https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html#limits-naming-rules
  # S3 - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html#bucketnamingrules
  lock_table_name   = "terraform-test-yccqf0J7fhRiTrWwwwxmwHwUMKzvkzvqeWhnqLdE6BjvnbUDcocrYfmLKWeFc0Hj0cwRg3PPLt6hVyEfTUrxjm9f5dD6Cq10YiQpKP8v0nilVehzpGVImvznHlPEiWzMNl1qB8zBRsgtEudDU2WMjTkg31c9plClgbPqNYCxL92V0gKY9Y3VoREsA4oFk2XcpcnHipPwjGRgBlyMT4e51Kg6vNcCcGXpKFoEgjGmBEyd0cG9"
  state_bucket_name = "terraform-test-18hg1l45lztagh48vwpugsnex8hzb4a2wh4nov7yax8k0cpf"
}
