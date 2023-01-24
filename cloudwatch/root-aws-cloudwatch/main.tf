module "cloudwatch" {
  source = "../module-aws-cloudwatch"
}

output "flow_logs" {
  value = module.cloudwatch.flow_logs
}

output "log_group" {
  value = module.cloudwatch.log_group
}

output "iam_role" {
  value = module.cloudwatch.iam_role
}

output "iam_role_policy" {
  value = module.cloudwatch.iam_role_policy
}
