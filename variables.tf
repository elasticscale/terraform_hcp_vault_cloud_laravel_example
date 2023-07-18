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

variable "image_url" {
  default     = "httpd:latest"
  description = "Image URL to use for the container"
  type        = string
}