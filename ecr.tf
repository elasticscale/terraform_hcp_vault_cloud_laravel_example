resource "aws_ecr_repository" "laravel" {
  name                 = "${var.prefix}laravel"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "vault" {
  name                 = "${var.prefix}vault"
  image_tag_mutability = "MUTABLE"
}