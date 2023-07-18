resource "aws_ecr_repository" "laravel" {
  name                 = "${var.prefix}laravel"
  image_tag_mutability = "MUTABLE"
}