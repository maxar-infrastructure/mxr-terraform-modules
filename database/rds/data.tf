data "aws_kms_key" "rds_default_key" {
  key_id = "alias/aws/rds"
}
