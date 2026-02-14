output "vm_health_check_s3_key" {
  value = aws_s3_object.vm_health_check.id
}

output "vm_health_check_script" {
  value = "${var.project_prefix}/${var.env}/scripts/vm_health_check.sh"
}

output "vm_health_check_s3_path" {
  value = "s3://${var.backup_bucket}/${var.project_prefix}/${var.env}/scripts/vm_health_check.sh"
}
