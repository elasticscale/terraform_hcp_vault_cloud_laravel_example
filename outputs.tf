output "load_balancer_url" {
  value = module.alb.lb_dns_name
}

output "vault_url" {
  value = hcp_vault_cluster.vault.vault_public_endpoint_url
}