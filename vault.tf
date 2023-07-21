# this file is uncommented with a reason, it will only work if you have a vault server running and the vault_url variable set + VAULT_TOKEN environment variable
# normally we would solve this with terragrunt modules that automatically provision vault, but that is out of scope for this demo

# terraform {
#   required_providers {
#     vault = {
#       source  = "hashicorp/vault"
#       version = "3.18.0"
#     }
#   }
# }

# provider "vault" {
#   address = var.vault_url
# }

# // secrets mount
# resource "vault_mount" "generic" {
#   path        = "secret"
#   type        = "kv-v2"
#   description = "Key value store for generic secrets"
# }

# resource "vault_generic_secret" "laravel" {
#   depends_on = [
#     vault_mount.generic
#   ]
#   path         = "secret/dynamic/laravel"
#   disable_read = true
#   lifecycle {
#     ignore_changes = [
#       data_json
#     ]
#   }
#   data_json = <<EOT
# {
#   "app_name":   "Laravel",
#   "app_env":   "production",
#   "app_key":   "",
#   "app_debug":   "false",
#   "app_url": "http://${module.alb.lb_dns_name}"
# }
# EOT
# }

# resource "vault_generic_secret" "db" {
#   depends_on = [
#     vault_mount.generic
#   ]
#   path         = "secret/dynamic/mysql"
#   disable_read = true
#   lifecycle {
#     ignore_changes = [
#       data_json
#     ]
#   }
#   data_json = <<EOT
# {
#   "hostname":   "${module.aurora_mysql_v2.cluster_endpoint}",
#   "port":   "${module.aurora_mysql_v2.cluster_port}",
#   "database":   "${module.aurora_mysql_v2.cluster_database_name}"
# }
# EOT
# }

# // mysql mount

# resource "vault_mount" "rds" {
#   path        = "database"
#   type        = "database"
#   description = "MySQL RDS rotation"
# }

# locals {
#   roles = var.vault_url != "" ? [
#     "laravel"
#   ] : []
# }

# resource "vault_database_secret_backend_connection" "mysql_connection" {
#   backend           = vault_mount.rds.path
#   name              = "mysql"
#   verify_connection = true
#   allowed_roles     = local.roles
#   mysql_aurora {
#     connection_url = "{{username}}:{{password}}@tcp(${module.aurora_mysql_v2.cluster_endpoint}:${module.aurora_mysql_v2.cluster_port})/${module.aurora_mysql_v2.cluster_database_name}"
#     username       = module.aurora_mysql_v2.cluster_master_username
#     password       = module.aurora_mysql_v2.cluster_master_password
#   }
# }
# resource "vault_database_secret_backend_role" "mysql_roles" {
#   for_each            = toset(local.roles)
#   default_ttl         = 86350
#   max_ttl             = 86400
#   backend             = vault_mount.rds.path
#   name                = each.value
#   db_name             = vault_database_secret_backend_connection.mysql_connection.name
#   creation_statements = ["CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL ON ${module.aurora_mysql_v2.cluster_database_name}.* TO '{{name}}'@'%' WITH GRANT OPTION;"]
# }

# # rotate rds credentials, so the password for the root user is stored in vault instead of the statefile
# resource "vault_generic_endpoint" "rotate_initial_db_password_mysql" {
#   depends_on     = [vault_database_secret_backend_connection.mysql_connection]
#   path           = "database/rotate-root/${vault_database_secret_backend_connection.mysql_connection.name}"
#   disable_read   = true
#   disable_delete = true
#   data_json      = "{}"
# }

# # aws authentication backend, allows us to authenticate to vault with iam roles

# resource "aws_iam_user" "vault_user" {
#   name = "${var.prefix}vault-user"
# }

# resource "aws_iam_access_key" "vault_access_key" {
#   user = aws_iam_user.vault_user.name
# }

# resource "aws_iam_policy" "vault_policy" {
#   name        = "${var.prefix}vault-policy"
#   description = "Policy for vault user to verify aws iam roles"
#   policy      = file("${path.module}/vault-policy.json")
# }

# resource "aws_iam_user_policy_attachment" "attach-policy-vault" {
#   user       = aws_iam_user.vault_user.name
#   policy_arn = aws_iam_policy.vault_policy.arn
# }

# resource "vault_auth_backend" "aws_auth" {
#   type        = "aws"
#   description = "Auth via execution roles"
#   tune {
#     default_lease_ttl = "28800s"
#     max_lease_ttl     = "28800s"
#   }
# }

# resource "vault_aws_auth_backend_client" "aws_auth_client" {
#   backend    = vault_auth_backend.aws_auth.path
#   access_key = aws_iam_access_key.vault_access_key.id
#   secret_key = aws_iam_access_key.vault_access_key.secret
# }


# resource "vault_aws_auth_backend_role" "laravelrole" {
#   backend = vault_auth_backend.aws_auth.path
#   // needs to match what is in the vault configuration (this is NOT the AWS role but the vault role)
#   role      = "laravel"
#   auth_type = "iam"
#   token_policies = [
#     "read_all_secrets", "read_rds_credentials_laravel"
#   ]
#   bound_iam_principal_arns = [
#     // bind it to just these roles in aws
#     module.ecs.services["${var.prefix}laravel"]["tasks_iam_role_arn"],
#   ]
#   resolve_aws_unique_ids = false
# }

# // create the policies
# resource "vault_policy" "read_all_secrets" {
#   name   = "read_all_secrets"
#   policy = <<EOT
# path "secret/*" {
#   capabilities = ["read", "list"]
# }
# EOT
# }

# resource "vault_policy" "read_rds_credentials_laravel" {
#   name   = "read_rds_credentials_laravel"
#   policy = <<EOT
# path "database/creds/laravel" {
#   capabilities = ["read"]
# }
# EOT
# }