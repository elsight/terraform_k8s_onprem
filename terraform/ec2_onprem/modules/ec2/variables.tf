variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet in the VPC"
  type        = string
}

variable "instance_configs" {
  description = "Map of instance configurations. Key is the instance name."
  type = map(object({
    instance_type   = optional(string, "t3.medium")
    enable_s3_mount = optional(bool, false)
    volume = optional(object({
      size = optional(number, 50)
      type = optional(string, "gp3")
    }), {})
    additional_security_rules = optional(list(object({
      type        = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    })), [])
  }))
}

variable "s3_bucket_name" {
  description = "The S3 bucket name to mount"
  type        = string
  default     = null
}

variable "s3_mount_point" {
  description = "The mount point path on the instance"
  type        = string
  default     = "/mnt/s3"
}

variable "s3_mount_readonly" {
  description = "Whether to mount as read-only"
  type        = bool
  default     = true
}

variable "s3_instance_profile_name" {
  description = "The IAM instance profile name for S3 access"
  type        = string
  default     = null
}
