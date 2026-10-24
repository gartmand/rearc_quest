resource "aws_ecr_repository" "rearc_quest" {
  name                 = "rearc_quest"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest"
    filter_type = "WILDCARD"
  }

  image_tag_mutability_exclusion_filter {
    filter      = "feature-*"
    filter_type = "WILDCARD"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
