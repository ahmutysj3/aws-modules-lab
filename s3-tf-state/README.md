# **AWS S3 Bucket Module**

### Overview 

- **builds** 2 x AWS S3 buckets 
    - 1 bucket is "locked" using an object locking configuration with 7 day retention
    - 1 bucket is "unlocked" and does not have object lock enabled
    - both buckets use version control and server side encryption
- **builds** aws kms key to be used for both buckets
- **builds** bucket policy and assigns to terraform bucket

### Resources Used
- aws_kms_key
- aws_dynamodb_table
- aws_s3_bucket
- aws_s3_bucket_server_side_encryption_configuration
- aws_s3_bucket_policy
- aws_s3_bucket_versioning
- aws_s3_bucket_object_lock_configuration

### Instructions

*this assumes that your credentials are stored in /.aws/config (default location)*
1. git clone repo
2. add `terraform.tfvars` and provide values for `var.region` and `var.user_arn` 
3. cd to the repo root dir and run terraform init & terraform apply
4. the unlocked bucket can be used to store a non-object-locked terraform state file remotely in S3. The locked bucket can store an object locked remote state to prevent accidential deletion.