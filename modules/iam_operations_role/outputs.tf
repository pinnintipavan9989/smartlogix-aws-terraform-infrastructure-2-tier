output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}
output "operations_role_name" {
  value = aws_iam_role.operations_analyst.name
}

output "operations_role_arn" {
  value = aws_iam_role.operations_analyst.arn
}