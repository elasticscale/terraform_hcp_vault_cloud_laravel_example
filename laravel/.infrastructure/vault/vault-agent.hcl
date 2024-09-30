pid_file = "/tmp/vault-pid"

vault {
  retry {
    num_retries = 5
  }
}

auto_auth {
  method "aws" {
    mount_path = "auth/aws"
    namespace  = "admin"
    config = {
      type = "iam"
      role = "laravel"
    }
  }
}

template {
  source      = "/etc/vault/vault-template.ctmpl"
  destination = "/etc/vault/.env"
}
