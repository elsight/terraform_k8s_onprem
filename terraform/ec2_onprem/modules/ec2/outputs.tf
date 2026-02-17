output "instance_ids" {
  description = "Map of instance name to instance ID"
  value       = { for k, v in aws_instance.this : k => v.id }
}

output "instance_private_ips" {
  description = "Map of instance name to private IP"
  value       = { for k, v in aws_instance.this : k => v.private_ip }
}

output "instance_public_ips" {
  description = "Map of instance name to public IP"
  value       = { for k, v in aws_instance.this : k => v.public_ip }
}

output "key_path" {
  description = "Path to the generated private key file for SSH"
  value       = local_file.ec2_key.filename
}
