data "aws_caller_identity" "current" {}

locals {
  environment_name = "development"
  account_id = data.aws_caller_identity.current.account_id
  oidc_provider_arn = data.aws_iam_openid_connect_provider.github_oidc.arn
}
