variable "instance_names" {
  description = "Unique names for each EC2 instance. Add or remove names to scale instances."
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet in the VPC"
  type        = string
}
