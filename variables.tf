variable "aws_region" {
  type = string
}

variable "project_prefix" {
  type = string
}

variable "env" {
  type = string
}

variable "api_instance_type" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_engine" {
  type = string
}

variable "db_engine_version" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "admin_email" {
  type = string
}

variable "ec2_instance_profile_name" {
  type = string
}

variable "backup_bucket_name" {
  type = string
}

variable "alerts_sns_name" {
  type = string
}

variable "ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH into EC2"
}

variable "CWA_DEB_URL" {
  type = string
}
