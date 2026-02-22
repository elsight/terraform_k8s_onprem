terraform {
  backend "s3" {
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

module "ec2" {
  source = "./modules/ec2"

  vpc_id         = local.vpc_id
  subnet_id      = local.subnet_id
  instance_configs = var.instance_configs

  # S3 mount configuration
  s3_bucket_name               = local.s3_mount_enabled ? data.terraform_remote_state.s3_bucket.outputs.bucket_name : null
  s3_mount_point               = var.s3_mount_point
  s3_mount_readonly            = var.s3_mount_readonly
  s3_instance_profile_name     = local.s3_mount_enabled ? aws_iam_instance_profile.ec2_s3_mount[0].name : null
}
