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
      name             = "${var.prefix}laravel"
      backend_protocol = "HTTP"
      backend_port     = "80"
      target_type      = "ip"
    },
  ]
}

module "ecs" {
  source       = "terraform-aws-modules/ecs/aws"
  cluster_name = "${var.prefix}cluster"
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }
  services = {
    ecsdemo-frontend = {
      cpu    = 1024
      memory = 4096
      container_definitions = {
        "${var.prefix}laravel" = {
          readonly_root_filesystem = false
          cpu                      = 512
          memory                   = 1024
          essential                = true
          image                    = "httpd:latest"
          port_mappings = [
            {
              containerPort = 80
              protocol      = "tcp"
            }
          ]
          enable_cloudwatch_logging = true
        }
      }
      load_balancer = {
        service = {
          target_group_arn = module.alb.target_group_arns[0]
          container_name   = "${var.prefix}laravel"
          container_port   = 80
        }
      }
      subnet_ids = module.vpc.private_subnets
      security_group_rules = {
        alb_ingress_3000 = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          description              = "Laravel port"
          source_security_group_id = module.alb_sg.security_group_id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
}