variable "region" {
  default     = "eu-west-1"
  description = "Region to deploy to"
  type        = string
}

variable "prefix" {
  default     = "hcp-laravel-"
  description = "Prefix to use for all resources"
  type        = string
}

variable "vault_url" {
  default     = ""
  description = "URL to your Vault cluster, if you fill it in the Vault cluster will be provisioned"
  type        = string
}