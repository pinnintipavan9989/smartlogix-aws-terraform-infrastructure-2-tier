output "api_instance_id" {
  value = aws_instance.api.id
}

output "api_public_ip" {
  value = aws_instance.api.public_ip
}

output "api_private_ip" {
  value = aws_instance.api.private_ip
}

output "api_key_name" {
  value = aws_key_pair.kp.key_name
}

output "api_security_group_id" {
  value = aws_security_group.api_sg.id
}
