variable "instance_names" {
  description = "Unique names for each EC2 instance. Add or remove names to scale instances."
  type        = list(string)
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

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
