resource "aws_s3_object" "sample_incident" {
  bucket = var.ticket_bucket
  key    = "${var.project_prefix}/${var.env}/itsm/sample_incident.json"
  source = "${path.module}/files/sample_incident.json"
  acl    = "private"
}
