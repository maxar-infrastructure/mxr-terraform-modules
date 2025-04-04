#
# Module: tf_aws_rds
#

# Output the ID of the RDS instance
output "rds_instance_id" {
  value = aws_db_instance.main_rds_instance.id
}

# Output the address (aka hostname) of the RDS instance
output "rds_instance_address" {
  value = aws_db_instance.main_rds_instance.address
}

# Output endpoint (hostname:port) of the RDS instance
output "rds_instance_endpoint" {
  value = aws_db_instance.main_rds_instance.endpoint
}

# Output the ID of the Subnet Group
output "subnet_group_id" {
  value = aws_db_subnet_group.main_db_subnet_group.id
}

# Output DB security group ID
output "security_group_id" {
  value = aws_security_group.main_db_access.id
}

# Output DB name
output "db_database_name" {
  value = var.database_name
}

# Output DB username
output "db_username" {
  value = var.database_user
}

# Output DB password
output "db_password" {
  value = var.database_password
}

output "tags" {
  value = var.tags
}
