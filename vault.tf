# build the secrets key pair store
resource "vault_mount" "generic" {
  count       = var.vault_url != "" ? 1 : 0
  path        = "secret"
  type        = "kv-v2"
  description = "Key value store for generic secrets"
}

resource "vault_generic_secret" "laravel" {
  count = var.vault_url != "" ? 1 : 0
  depends_on = [
    vault_mount.generic
  ]
  path         = "secret/dynamic/laravel"
  disable_read = true
  lifecycle {
    ignore_changes = [
      data_json
    ]
  }
  data_json = <<EOT
{
  "app_name":   "Laravel",
  "app_env":   "production",
  "app_key":   "",
  "app_debug":   "false",
  "app_url": "http://${module.alb.lb_dns_name}"
}
EOT
}

resource "vault_mount" "rds" {
  count       = var.vault_url != "" ? 1 : 0
  path        = "database"
  type        = "database"
  description = "MySQL RDS rotation"
}

locals {
  roles = var.vault_url != "" ? [
    "laravel"
  ] : []
}

resource "vault_database_secret_backend_connection" "mysql_connection" {
  count             = var.vault_url != "" ? 1 : 0
  backend           = vault_mount.rds[0].path
  name              = "mysql"
  verify_connection = true
  allowed_roles     = local.roles
  mysql_aurora {
    connection_url = "{{username}}:{{password}}@tcp(${module.aurora_mysql_v2.cluster_endpoint}:${module.aurora_mysql_v2.cluster_port})/${module.aurora_mysql_v2.cluster_database_name}"
  }
  data = {
    username = module.aurora_mysql_v2.cluster_master_username
    password = module.aurora_mysql_v2.cluster_master_password
  }
}

resource "vault_database_secret_backend_role" "mysql_roles" {
  for_each            = toset(local.roles)
  default_ttl         = 86350
  max_ttl             = 86400
  backend             = vault_mount.rds[0].path
  name                = each.value
  db_name             = vault_database_secret_backend_connection.mysql_connection[0].name
  creation_statements = ["CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL ON ${module.aurora_mysql_v2.cluster_database_name}.* TO '{{name}}'@'%' WITH GRANT OPTION;"]
}

# rotate rds credentials so the mysql credentials in the state are not correct anymore
# resource "vault_generic_endpoint" "rotate_initial_db_password_mysql" {
#   count          = var.vault_url != "" ? 1 : 0
#   depends_on     = [vault_database_secret_backend_connection.mysql_connection]
#   path           = "database/rotate-root/${vault_database_secret_backend_connection.mysql_connection.name}"
#   disable_read   = true
#   disable_delete = true
#   data_json      = "{}"
# }