output "iam_role_policy" {
  value = aws_iam_role_policy.main
}

output "iam_role" {
  value = aws_iam_role.main
}

output "log_group" {
  value = aws_cloudwatch_log_group.main
}

output "flow_logs" {
  value = aws_flow_log.main
}