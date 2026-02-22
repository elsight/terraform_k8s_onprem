variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC. Omit to use the default VPC."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "ID of the subnet in the VPC. Omit to use the first subnet in the VPC."
  type        = string
  default     = null
}

variable "instance_configs" {
  description = "Map of instance configurations. Key is the instance name."
  type = map(object({
    instance_type    = optional(string, "t3.medium")
    enable_s3_mount  = optional(bool, false)
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

variable "s3_mount_point" {
  description = "The mount point path on the instance where the S3 bucket will be mounted"
  type        = string
  default     = "/mnt/s3"
}

variable "s3_mount_readonly" {
  description = "Whether to mount the S3 bucket as read-only. If false, allows writing new files (but not deletes unless explicitly enabled)"
  type        = bool
  default     = true
}

variable "s3_mount_allow_delete" {
  description = "Whether to allow delete operations on the S3 bucket. Only applicable if s3_mount_readonly is false"
  type        = bool
  default     = false
}
