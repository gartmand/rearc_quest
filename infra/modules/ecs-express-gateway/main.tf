variable "environment_name" {
  type = string
}

variable "primary_container_image" {
  type = string
}

data "aws_secretsmanager_secret" "app_secret_code" {
  # For purposes of this project, it doesn't vary based on environment. But it would IRL.
  # This pollutes this module a little bit. In theory we could pass in secrets mappings as vars,
  # then inline them into the container's secrets definitions, but that's a bit more work.
  name = "rearc_quest/app-secret-code"
}

resource "aws_iam_role" "ecs_express_gateway_execution_role" {
  name = "ecs-express-gateway-execution-role-${var.environment_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "express_execution_secrets" {
  name = "express-execution-secrets-policy-${var.environment_name}"
  role = aws_iam_role.ecs_express_gateway_execution_role.id

  # Uses a mildly hacky way to make sure that the policy will grant access to the
  # *actual* ARN of the secret, in case of secret recreation in between TF applies,
  # so the policy still applies to the new secret version's ARN. AWS appends a suffix to the name to make the arn.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "${replace(data.aws_secretsmanager_secret.app_secret_code.arn, "/-[a-zA-Z0-9]{6}$/", "-*")}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_express_gateway_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_express_gateway_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_express_gateway_infrastructure_role" {
  name = "ecs-express-gateway-infra-role-${var.environment_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccessToECSForInfrastructureManagement"
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Cover a gap in policies that's showing an access denied in CloudTrail
resource "aws_iam_role_policy" "ecs_infra_role_supplemental" {
  name = "ecs-express-gateway-infra-supplemental-${var.environment_name}"
  role = aws_iam_role.ecs_express_gateway_infrastructure_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowDescribeAccountAttributes"
        Effect   = "Allow"
        Action   = "ec2:DescribeAccountAttributes"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_express_gateway_infrastructure_role_policy_attachment" {
  role       = aws_iam_role.ecs_express_gateway_infrastructure_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
}

# The above policy attachment isn't quite enough; this should cover remaining gaps
resource "aws_iam_role_policy_attachment" "ecs_express_gateway_infrastructure_role_shared_alb_policy_attachment" {
  role       = aws_iam_role.ecs_express_gateway_infrastructure_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRoleForGatewayHostSharedALB"
}

# This is the core functionality of the entire repo, really - besides the Dockerfile and app themselves.
# AWS magic will set up an ALB, DNS records, SSL cert, target group, ECS cluster, etc. automatically from this.
# In a more commercial scenario, it's more likely I would take advantage of an EKS cluster.
resource "aws_ecs_express_gateway_service" "rearc_quest_service" {
  execution_role_arn      = aws_iam_role.ecs_express_gateway_execution_role.arn
  infrastructure_role_arn = aws_iam_role.ecs_express_gateway_infrastructure_role.arn
  primary_container {
    image          = var.primary_container_image
    container_port = 3000

    secret {
      name       = "SECRET_WORD"
      value_from = data.aws_secretsmanager_secret.app_secret_code.arn
    }
  }

  # The gateway service implicitly depends on the execution role and infrastructure role being created,
  # but the attached policies might not be created by the time the service tries to create, resulting in
  # various access denied errors. Force them to create and attach first.
  depends_on = [
    aws_iam_role_policy.ecs_infra_role_supplemental,
    aws_iam_role_policy.express_execution_secrets,
    aws_iam_role_policy_attachment.ecs_express_gateway_infrastructure_role_policy_attachment,
    aws_iam_role_policy_attachment.ecs_express_gateway_infrastructure_role_shared_alb_policy_attachment,
    aws_iam_role_policy_attachment.ecs_express_gateway_execution_role_policy_attachment
  ]
}

output "ingress_paths" {
  value       = aws_ecs_express_gateway_service.rearc_quest_service.ingress_paths
  description = "The auto-generated HTTPS endpoint(s) for the application"
}


