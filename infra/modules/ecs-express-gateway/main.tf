variable "environment_name" {
  type = string
}

variable "primary_container_image" {
  type = string
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

resource "aws_iam_role_policy_attachment" "ecs_express_gateway_infrastructure_role_policy_attachment" {
  role       = aws_iam_role.ecs_express_gateway_infrastructure_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
}


resource "aws_ecs_express_gateway_service" "rearc_quest_service" {
  execution_role_arn      = aws_iam_role.ecs_express_gateway_execution_role.arn
  infrastructure_role_arn = aws_iam_role.ecs_express_gateway_infrastructure_role.arn
  primary_container {
    image          = var.primary_container_image
    container_port = 3000
  }

}

output "application_url" {
  value       = aws_ecs_express_gateway_service.rearc_quest_service.dns_name
  description = "The auto-generated HTTPS endpoint for your application"
}
