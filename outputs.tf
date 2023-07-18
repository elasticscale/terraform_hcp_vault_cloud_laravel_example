output "load_balancer_url" {
  value = module.alb.lb_dns_name
}