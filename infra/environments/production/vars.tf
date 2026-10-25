variable "github_org_or_user" {
  description = "The GitHub organization or user that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "The GitHub repository name."
  type        = string
}

variable "ecr_image_tag" {
  description = "The tag of the image to deploy."
  default     = "latest" # Might not be wise in Prod, but this is a demo.
  type        = string
}
