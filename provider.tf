terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.8.0"
    }
  }
}

// this setup was tested with v1.5.3
provider "aws" {
  region = var.region
}

