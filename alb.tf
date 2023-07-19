module "alb_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "5.1.0"
  name                = "${var.prefix}service"
  description         = "ALB security group"
  vpc_id              = module.vpc.vpc_id
  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = module.vpc.private_subnets_cidr_blocks
}

module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "8.7.0"
  name               = "${var.prefix}alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]
  target_groups = [
    {
      name             = "${var.prefix}web"
      backend_protocol = "HTTP"
      backend_port     = "8080"
      target_type      = "ip"
      health_check = {
        enabled = true
        matcher = "200-499"
        // we use the robots.txt of laravel for the healthcheck
        path = var.image_url == "httpd:latest" ? "/" : "/robots.txt"
      }
    },
  ]
}