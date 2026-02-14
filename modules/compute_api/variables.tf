variable "project_prefix" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "api_instance_type" {
  type = string
}

variable "db_endpoint" {
  type      = string
  sensitive = true
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "iam_instance_profile" {
  type    = string
  default = ""
}

variable "ssh_cidr" {
  type = string
}

variable "ROWS" {
  type    = number
  default = 0
}

variable "CWA_DEB_URL" {
  type = string
}
