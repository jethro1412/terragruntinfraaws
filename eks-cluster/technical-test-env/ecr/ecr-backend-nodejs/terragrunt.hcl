terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-ecr//."
}

inputs = {

  repository_name = "backend-nodejs"

  repository_image_tag_mutability = "IMMUTABLE"

  repository_image_scan_on_push = false

  repository_type = "private"

  create_repository_policy = false

  create_lifecycle_policy = false

  attach_repository_policy = false

}