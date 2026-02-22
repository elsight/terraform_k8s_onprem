# IAM role for S3 mounting (only created if any instance has enable_s3_mount = true)
resource "aws_iam_role" "ec2_s3_mount" {
  count = local.s3_mount_enabled ? 1 : 0

  name = "ec2-s3-mount-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "ec2-s3-mount-${var.environment}"
    Environment = var.environment
  }
}

# IAM policy for S3 bucket access
resource "aws_iam_role_policy" "ec2_s3_mount" {
  count = local.s3_mount_enabled ? 1 : 0

  name = "s3-mount-access"
  role = aws_iam_role.ec2_s3_mount[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "s3:ListBucket"
          ]
          Resource = "arn:aws:s3:::${data.terraform_remote_state.s3_bucket.outputs.bucket_name}"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject"
          ]
          Resource = "arn:aws:s3:::${data.terraform_remote_state.s3_bucket.outputs.bucket_name}/*"
        }
      ],
      # Add write permissions if not readonly
      var.s3_mount_readonly ? [] : [
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:AbortMultipartUpload"
          ]
          Resource = "arn:aws:s3:::${data.terraform_remote_state.s3_bucket.outputs.bucket_name}/*"
        }
      ],
      # Add delete permissions if explicitly enabled
      var.s3_mount_allow_delete && !var.s3_mount_readonly ? [
        {
          Effect = "Allow"
          Action = [
            "s3:DeleteObject"
          ]
          Resource = "arn:aws:s3:::${data.terraform_remote_state.s3_bucket.outputs.bucket_name}/*"
        }
      ] : []
    )
  })
}


# Instance profile
resource "aws_iam_instance_profile" "ec2_s3_mount" {
  count = local.s3_mount_enabled ? 1 : 0

  name = "ec2-s3-mount-${var.environment}"
  role = aws_iam_role.ec2_s3_mount[0].name
}
