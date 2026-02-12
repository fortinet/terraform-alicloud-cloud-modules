output "vpc_id" {
  description = "VPC ID"
  value       = alicloud_vpc.vpc.id
}

output "vswitch_ids" {
  description = "VSwitch IDs"
  value       = alicloud_vswitch.vswitch[*].id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = alicloud_security_group.security_group.id
}
