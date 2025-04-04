# S3 Bucket

This folder contains a [Terraform](https://www.terraform.io/) module that can be used to deploy a s3 Bucket.

## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "s3_bucket_demo_app" {
  bucket_logging = "demo-logging"
  bucket_name = "demo-infra"
  logging_prefix = "demo-app"
  source = "../modules/s3_bucket"
}
```

Note the following required parameters:

* `bucket_logging`: The name of the bucket that will receive the log objects.
* `bucket_name`: The name of the bucket. If omitted, Terraform will assign a random, unique name.
* `logging_prefix`: To specify a key prefix for log objects.

Note the following optional parameters:

* `bucket_acl`: The canned ACL to apply. Defaults to "private".
* `bucket_versioning`: Enable versioning. Once you version-enable a bucket, it can never return to an unversioned state. You can, however, suspend versioning on that bucket.
* `enable_default_lifecycle`: Enable a lifecycle configuration with the default parameters (transition to glacier after 90 days, expire after 7 years). If this variable is false or empty, no lifecycle will be created.
* `tags`: The tags you want to set on the resources created in this module.

Note the following outputs:

* `bucket_id`: The name of the bucket.
* `bucket_arn`: The ARN of the bucket. Will be of format arn:aws:s3:::bucketname.
* `bucket_region`: The AWS region this bucket resides in.

## What does this module consists of?

This module consists of the following resources:

* [aws_s3_bucket](https://www.terraform.io/docs/providers/aws/r/s3_bucket.html)
