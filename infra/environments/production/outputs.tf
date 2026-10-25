output "ingress_paths" {
  value       = module.ecs_express_gateway.ingress_paths
  description = "The auto-generated HTTPS endpoint(s) for the application"
}
