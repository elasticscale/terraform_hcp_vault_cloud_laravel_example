terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.18.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.8.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.66"
    }
  }
}

// this setup was tested with v1.5.3
provider "aws" {
  region = var.region
}

provider "hcp" {}