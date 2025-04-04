//
// Module: tf_aws_rds
//

// This template creates the following resources
// - An RDS instance
// - A database subnet group
// - You should want your RDS instance in a VPC

resource "aws_db_instance" "main_rds_instance" {
  identifier                            = var.rds_instance_identifier
  allocated_storage                     = var.rds_allocated_storage
  ca_cert_identifier                    = var.ca_cert_identifier != null ? var.ca_cert_identifier : null
  engine                                = var.rds_engine_type
  engine_version                        = var.rds_engine_version
  instance_class                        = var.rds_instance_class
  db_name                               = var.database_name
  username                              = var.database_user
  password                              = var.database_password
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled == false ? null : data.aws_kms_key.rds_default_key.arn
  performance_insights_retention_period = var.performance_insights_enabled == false ? null : var.performance_insights_retention_period

  port = var.database_port

  # Because we're assuming a VPC, we use this option, but only one SG id
  vpc_security_group_ids = [aws_security_group.main_db_access.id]

  # We're creating a subnet group in the module and passing in the name
  db_subnet_group_name = aws_db_subnet_group.main_db_subnet_group.id
  parameter_group_name = var.use_external_parameter_group ? var.parameter_group_name : aws_db_parameter_group.main_rds_instance[0].id

  # We want the multi-az setting to be toggleable, but off by default
  multi_az            = var.rds_is_multi_az
  storage_type        = var.rds_storage_type
  storage_encrypted   = var.storage_encrypted
  iops                = var.rds_iops
  publicly_accessible = var.publicly_accessible

  # Upgrades
  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  maintenance_window          = var.maintenance_window

  # Snapshots and backups
  skip_final_snapshot   = var.skip_final_snapshot
  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window

  # enhanced monitoring
  monitoring_interval = var.monitoring_interval

  tags = merge(
    var.tags,
    {
      "Name" = format("%s", var.rds_instance_identifier)
    },
  )
}

resource "aws_db_parameter_group" "main_rds_instance" {
  count = var.use_external_parameter_group ? 0 : 1

  name   = "${var.rds_instance_identifier}-${replace(var.db_parameter_group, ".", "")}-custom-params"
  family = var.db_parameter_group

  # Force TLS
  parameter {
    apply_method = "immediate"
    name         = "rds.force_ssl"
    value        = "1"
  }

  # parameter {
  #   name = "character_set_client"
  #   value = "utf8"
  # }

  tags = merge(
    var.tags,
    {
      "Name" = format("%s", var.rds_instance_identifier)
    },
  )
}

resource "aws_db_subnet_group" "main_db_subnet_group" {
  name        = "${var.rds_instance_identifier}-subnetgrp"
  description = "RDS subnet group"
  subnet_ids  = var.subnets

  tags = merge(
    var.tags,
    {
      "Name" = format("%s", var.rds_instance_identifier)
    },
  )
}

# Security groups
resource "aws_security_group" "main_db_access" {
  name        = "${var.rds_instance_identifier}-access"
  description = "Allow access to the database"
  vpc_id      = var.rds_vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = format("%s", var.rds_instance_identifier)
    },
  )
}

resource "aws_security_group_rule" "allow_db_access_cidr" {
  count       = length(var.private_cidr) == 0 ? 0 : 1
  description = "Allow database access from a specific CIDR"
  type        = "ingress"


  from_port   = var.database_port
  to_port     = var.database_port
  protocol    = "tcp"
  cidr_blocks = var.private_cidr

  security_group_id = aws_security_group.main_db_access.id
}

resource "aws_security_group_rule" "allow_db_access_sg" {
  count       = length(var.private_cidr) == 0 ? 1 : 0
  description = "Allow database access from a specific security group"
  type        = "ingress"

  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = var.app_security_group

  security_group_id = aws_security_group.main_db_access.id
}


resource "aws_security_group_rule" "allow_all_outbound" {
  description = "Allow database outbound access"
  type        = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = aws_security_group.main_db_access.id
}
