module "github_aws_role" {
  source             = "../../modules/github-aws-role"
  oidc_provider_arn  = local.oidc_provider_arn
  github_org_or_user = var.github_org_or_user
  github_repo        = var.github_repo
  environment_name   = local.environment_name
}

module "ecs_express_gateway" {
  source                  = "../../modules/ecs-express-gateway"
  environment_name        = local.environment_name
  primary_container_image = local.ecr_repository_url
}
