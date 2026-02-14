resource "aws_s3_object" "vm_health_check" {
  bucket = var.backup_bucket
  key    = "${var.project_prefix}/${var.env}/scripts/vm_health_check.sh"

  content = templatefile("${path.module}/files/vm_health_check.sh.tpl", {
    backup_bucket  = var.backup_bucket
    project_prefix = var.project_prefix
    env            = var.env
  })

  metadata = {
    owner = "Automation"
  }

  # Forces S3 object update when template changes
  etag = md5(templatefile("${path.module}/files/vm_health_check.sh.tpl", {
    backup_bucket  = var.backup_bucket
    project_prefix = var.project_prefix
    env            = var.env
  }))
}
