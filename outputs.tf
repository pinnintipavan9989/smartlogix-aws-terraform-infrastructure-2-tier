output "api_public_ip" {
  value       = module.compute_api.api_public_ip
  description = "Public IP of the API EC2 instance"
}

output "api_instance_id" {
  value       = module.compute_api.api_instance_id
  description = "EC2 Instance ID for API server"
}

output "api_security_group_id" {
  value       = module.compute_api.api_security_group_id
  description = "Security Group ID used for API EC2"
}

output "ec2_instance_profile" {
  value       = module.iam_operations_role.ec2_instance_profile_name
  description = "IAM Instance Profile attached to EC2"
}

output "backup_bucket" {
  value       = module.s3_backup.backup_bucket_name
  description = "S3 bucket storing backups, scripts, and reports"
}

output "backup_bucket_url" {
  value       = "https://s3.console.aws.amazon.com/s3/buckets/${module.s3_backup.backup_bucket_name}"
  description = "AWS console URL for backup bucket"
}

output "automation_scripts_path" {
  value       = "${var.project_prefix}/${var.env}/scripts"
  description = "Prefix in S3 where automation scripts are stored"
}

output "sample_incident_key" {
  value       = module.itsm_simulation.sample_incident_key
  description = "ITSM sample incident file key in S3"
}

output "db_identifier" {
  value       = module.db.db_identifier
  description = "RDS instance identifier"
}

output "db_endpoint" {
  value       = module.db.db_endpoint
  description = "RDS endpoint URL"
}

output "db_port" {
  value       = module.db.db_port
  description = "RDS port number"
}

output "db_username" {
  value       = module.db.db_username
  description = "RDS admin username"
}

output "rds_connection_string" {
  value       = "mysql -h ${module.db.db_endpoint} -u ${module.db.db_username} -p"
  description = "Command to connect to DB"
}

output "sns_topic_arn" {
  value       = module.monitoring.sns_topic_arn
  description = "SNS topic ARN for alerting"
}

output "sns_dashboard_name" {
  value       = module.monitoring.dashboard_name
  description = "CloudWatch dashboard name"
}

output "sns_topic_subscribed_email" {
  value       = var.admin_email
  description = "Email subscribed to alarms"
}

output "monitoring_dashboard_url" {
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.monitoring.dashboard_name}"
  description = "Direct link to CloudWatch dashboard"
}

output "cloudwatch_log_groups" {
  value = [
    "/aws/smartlogix/api",
    "/aws/smartlogix/db/slowquery"
  ]
  description = "Log groups created for monitoring"
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}