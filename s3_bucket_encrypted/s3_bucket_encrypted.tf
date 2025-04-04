# ---------------------------------------------------------------------------------------------------------------------
# THESE TEMPLATES REQUIRE TERRAFORM VERSION 0.9.11 AND ABOVE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.9.11"
}

# ---------------------------------------------------------------------------------------------------------------------
# Required Variables
# ---------------------------------------------------------------------------------------------------------------------

variable "bucket_logging" {
  description = "Target bucket for logs to be sent."
}

variable "logging_prefix" {
  description = "Desired path of logs in target log bucket. eg. <service-name>/logs/"
}

variable "bucket_name" {
  description = "Name of bucket you want to create."
}

# Should be set to "low" if the deployment is happening on the low side.
# Should be set to "high" if the deployment is happening in V3R or SC2S.
variable "classified_partition" {
  type = string
}

# Set to true if deployment is happening in V3R.
# Set to false if deployment is not happening in V3R.
variable "v3r" {
  type = bool
}

# ---------------------------------------------------------------------------------------------------------------------
# Optional Variables
# ---------------------------------------------------------------------------------------------------------------------

variable "bucket_versioning" {
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_default_lifecycle" {
  default     = false
  description = "Enable the default lifecycle configuration on the bucket"
  type        = bool

}

# ---------------------------------------------------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------------------------------------------------

output "bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}

output "bucket_id" {
  value = aws_s3_bucket.bucket.id
}

output "bucket_region" {
  value = aws_s3_bucket.bucket.region
}

# ---------------------------------------------------------------------------------------------------------------------
# Resources
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = merge(
    {
      "Name" = var.bucket_name
    },
    var.tags,
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
} 

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.bucket_versioning == "true" ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_configuration" {
  count = var.enable_default_lifecycle == true ? 1 : 0

  bucket = aws_s3_bucket.bucket.id
  rule {
    id      = "Transition90daysRetain7yrs"
    status  = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555
    }
  }
}

# Because the highside lacks the feature to request public access to be blocked.
# However, block public access is enable on the highside by default, so the end result is the same.
# This resource will fail on the highside. AWS support ticket is open on the highside.
# Once resolved we can remove the count attribute here.
resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  count = var.classified_partition == "low" || var.v3r == true ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Only do this on the low side since the logging buckets don't exist on the high side...
resource "aws_s3_bucket_logging" "bucket_logging" {
  count         = var.classified_partition == "low" || var.v3r == true ? 1 : 0
  bucket        = aws_s3_bucket.bucket.id
  target_bucket = var.bucket_logging
  target_prefix = var.logging_prefix
}
