module "github_aws_role" {
  source = "../../modules/github-aws-role"
  oidc_provider_arn = local.oidc_provider_arn
  github_org_or_user = var.github_org_or_user
  github_repo = var.github_repo
  environment_name = local.environment_name
}