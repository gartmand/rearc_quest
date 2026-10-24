# Given an OIDC provider, user or org, repo, and environment name,
# create a role that can be assumed by GitHub Actions in that environment.
# The attached policy will enforce that the role can only be assumed by the specified repo and GitHub environment.

variable "oidc_provider_arn" {
  type        = string
  description = "The ARN of the central GitHub Actions OIDC provider"
}

variable "github_org_or_user" {
  type        = string
}

variable "github_repo" {
  type        = string
}

variable "environment_name" {
  type        = string
  description = "Name used to make the role unique per environment"
}

resource "aws_iam_role" "github_actions_env" {
  name = "github-actions-${var.environment_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = [ "://amazonaws.com" ]
          }
          StringLike = {
            # Strictly pairs this environment's role to a specific GitHub environment and locks it to the specified repo 
            "token.actions.githubusercontent.com:environment" = [ var.environment_name ]
            "token.actions.githubusercontent.com:sub" = [ "repo:${var.github_org_or_user}/${var.github_repo}/*" ]
          }
        }
      }
    ]
  })
}

output "role_arn" {
  value = aws_iam_role.github_actions_env.arn
}
