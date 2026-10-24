# Declares a central OIDC provider to be used in GitHub Actions authentication.
# This is a bootstrap resource and should only be run once per account.

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com" 

  client_id_list = [
    "sts.amazonaws.com",
  ]
}
