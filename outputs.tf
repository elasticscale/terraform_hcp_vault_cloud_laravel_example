output "load_balancer_url" {
  value = module.alb.lb_dns_name
}

output "ecr_url" {
  value = "${aws_ecr_repository.laravel.repository_url}:latest"
}

output "vault_url" {
  value = hcp_vault_cluster.vault.vault_public_endpoint_url
}