output "repository_arn" {
  value       = aws_ecr_repository.rearc_quest.arn
  description = "The ARN of the ECR repository."
}

output "repository_url" {
  value       = aws_ecr_repository.rearc_quest.repository_url
  description = "The URL of the ECR repository."
}

output "repository_name" {
  value       = aws_ecr_repository.rearc_quest.name
  description = "The name of the ECR repository."
}
