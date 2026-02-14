output "sample_incident_key" {
  description = "Full S3 ID of the sample incident file"
  value       = aws_s3_object.sample_incident.id
}
