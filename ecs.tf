data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "ecs" {
  source       = "terraform-aws-modules/ecs/aws"
  version      = "5.2.0"
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
      volume = [
        { name = "vault-volume" }
      ]
      container_definitions = {
        "${var.prefix}laravel" = {
          readonly_root_filesystem = false
          essential                = true
          image                    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.prefix}laravel:latest"
          port_mappings = [
            {
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
          essential                 = true
          enable_cloudwatch_logging = true
          mount_points = [
            {
              sourceVolume  = "vault-volume",
              containerPath = "/etc/vault"
            }
          ]
          environment = [
            {
              name  = "ENVPATH"
              value = "/etc/vault/"
            }
          ]
        }
        "${var.prefix}vault" = {
          readonly_root_filesystem = false
          // normally should be true, but might not matter if just the httpd container is running
          essential                 = false
          image                     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.prefix}vault:latest"
          enable_cloudwatch_logging = true
          command                   = ["vault", "agent", "-log-level", "debug", "-config=/etc/vault/vault-agent.hcl"]
          dependsOn = [
            {
              containerName = "${var.prefix}laravel"
              condition     = "START"
            }
          ],
          mount_points = [
            {
              sourceVolume  = "vault-volume",
              containerPath = "/etc/vault"
            }
          ],
          environment = [
            {
              name  = "VAULT_ADDR"
              value = var.vault_url
            }
          ]
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
          from_port                = 8080
          to_port                  = 8080
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

// could also be done with task_exec_iam_statements, but this works as well
resource "aws_iam_role_policy" "ecs_exec_policy" {
  name   = "${var.prefix}ecs-exec-policy"
  role   = module.ecs.services["${var.prefix}laravel"]["tasks_iam_role_name"]
  policy = file("${path.module}/ecs-exec-policy.json")
}