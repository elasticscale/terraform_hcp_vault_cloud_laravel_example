resource "random_password" "password" {
  length  = 16
  special = false
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.prefix}db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

module "aurora_mysql_v2" {
  source                      = "terraform-aws-modules/rds-aurora/aws"
  version                     = "8.3.1"
  name                        = "${var.prefix}mysql"
  engine                      = "aurora-mysql"
  engine_mode                 = "provisioned"
  engine_version              = "8.0"
  storage_encrypted           = true
  manage_master_user_password = false
  master_username             = "root"
  master_password             = random_password.password.result
  vpc_id                      = module.vpc.vpc_id
  db_subnet_group_name        = aws_db_subnet_group.default.name
  database_name               = "db"
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
    hcp_ingress = {
      cidr_blocks = [hcp_hvn.hvn.cidr_block]
    }
  }
  monitoring_interval = 60
  apply_immediately   = true
  skip_final_snapshot = true
  serverlessv2_scaling_configuration = {
    min_capacity = 1
    max_capacity = 1
  }
  instance_class = "db.serverless"
  instances = {
    master = {}
  }
}