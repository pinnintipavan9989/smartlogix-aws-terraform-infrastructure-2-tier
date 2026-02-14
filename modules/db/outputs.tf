output "db_identifier" {
  value = aws_db_instance.mysql.id
}

output "db_endpoint" {
  value = aws_db_instance.mysql.address
}

output "db_port" {
  value = aws_db_instance.mysql.port
}

output "db_username" {
  value = var.db_username
}

output "db_subnet_group" {
  value = aws_db_subnet_group.this.name
}

output "db_security_group_id" {
  value = aws_security_group.db_sg.id
}
