output "vpc_id" {
  description = "VPC ID"
  value       = alicloud_vpc.vpc.id
}

output "router_id" {
  description = "VRouter ID"
  value       = alicloud_vpc.vpc.router_id
}

output "route_table_id" {
  description = "Default route table ID"
  value       = alicloud_vpc.vpc.route_table_id
}

output "vswitch_ids" {
  description = "VSwitch IDs in the same order as the vswitch input list."
  value       = [for vswitch in var.vswitch : alicloud_vswitch.vswitch["${vswitch.zone}/${vswitch.cidr}"].id]
}

output "vswitch_ids_by_zone_cidr" {
  description = "VSwitch IDs keyed by zone ID and CIDR block, such as cn-guangzhou-a/10.0.0.0/16."
  value       = { for key, vswitch in alicloud_vswitch.vswitch : key => vswitch.id }
}

output "security_group_id" {
  description = "Security Group ID"
  value       = alicloud_security_group.security_group.id
}
