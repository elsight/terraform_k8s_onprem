output "instance_ids" {
  description = "Map of instance name to instance ID"
  value       = module.ec2.instance_ids
}

output "instance_private_ips" {
  description = "Map of instance name to private IP"
  value       = module.ec2.instance_private_ips
}

output "instance_public_ips" {
  description = "Map of instance name to public IP"
  value       = module.ec2.instance_public_ips
}
