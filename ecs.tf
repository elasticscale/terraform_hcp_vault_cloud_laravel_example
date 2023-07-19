

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
    "${var.prefix}laravel" = {
      cpu    = 1024
      memory = 4096
      container_definitions = {
        "${var.prefix}laravel" = {
          readonly_root_filesystem = false
          cpu                      = 512
          memory                   = 1024
          essential                = true
          image                    = var.image_url
          port_mappings = [
            {
              containerPort = 8080
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
          container_port   = 8080
        }
      }
      enable_execute_command = true
      subnet_ids             = module.vpc.private_subnets
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

// todo change to task_exec_iam_statements
resource "aws_iam_role_policy" "ecs_exec_policy" {
  name   = "${var.prefix}ecs-exec-policy"
  role   = module.ecs.services["${var.prefix}laravel"]["tasks_iam_role_name"]
  policy = file("${path.module}/ecs-exec-policy.json")
}