# Project
output "prefix" {
  description = "Generated resource prefix."
  value       = local.prefix
}

output "zones" {
  description = "Selected zones."
  value       = local.selected_zone_ids
}

output "fgt_username" {
  description = "Default FortiGate username."
  value       = "admin"
}

output "fgt_password" {
  description = "FortiGate admin password."
  value       = local.fgt_password
  sensitive   = true
}

output "autoscale_psksecret" {
  description = "FortiGate autoscale pre-shared key."
  value       = local.autoscale_psksecret
  sensitive   = true
}

output "ots_instance_name" {
  description = "OTS instance name for the example-managed state table. Null when all groups disable Function Compute."
  value       = try(module.autoscale_ots[0].name, null)
}

output "ots_table_name" {
  description = "Example-managed OTS state table name. Null when all groups disable Function Compute."
  value       = local.deploy_any_function ? local.ots_table_name : null
}

output "fortigate_asgs" {
  description = "FortiGate group resources keyed by the names in fortigate_asgs."
  # Resource identifiers are public metadata; credentials are separate sensitive outputs.
  value = {
    for name, group in module.fortigate_asg : name => {
      scaling_group_id         = nonsensitive(sensitive(group.scaling_group_id))
      scaling_configuration_id = nonsensitive(sensitive(group.scaling_configuration_id))
      cpu_alarm_ids            = nonsensitive(sensitive(group.cpu_alarm_ids))
      scaling_rule_aris = {
        scale_out = nonsensitive(sensitive(group.scaling_rule_aris.scale_out))
        scale_in  = nonsensitive(sensitive(group.scaling_rule_aris.scale_in))
      }
      oss_bucket_name   = nonsensitive(sensitive(group.oss_bucket_name))
      mns_topic_name    = nonsensitive(sensitive(group.mns_topic_name))
      ots_instance_name = nonsensitive(sensitive(group.ots_instance_name))
      ots_table_name    = nonsensitive(sensitive(group.ots_table_name))
    }
  }
}

# Security VPC
output "security_vpc_id" {
  description = "Security VPC ID."
  value       = module.security_vpc.vpc_id
}

output "security_vswitch_ids" {
  description = "Security VPC VSwitch IDs keyed by zone and purpose."
  value       = local.security_vswitch_ids
}

output "security_route_table_ids" {
  description = "Security VPC route table IDs keyed by purpose and zone ID."
  value = {
    inspection = { for zone_id, route_table in alicloud_route_table.security_inspection : zone_id => route_table.id }
    tr         = local.security_tr_route_table_ids
    gwlbe      = local.security_gwlbe_route_table_ids
    nat        = { for zone_id, route_table in alicloud_route_table.security_nat : zone_id => route_table.id }
  }
}

output "gwlb_addresses_by_zone" {
  description = "GWLB private addresses keyed by zone ID."
  value       = module.gwlb.addresses_by_zone
}

output "gwlbe_endpoint_ids" {
  description = "GWLBe endpoint IDs keyed by zone ID."
  value       = module.gwlbe.endpoint_ids
}

output "nat_gateway_ids" {
  description = "Security VPC CrossAZ NAT Gateway IDs keyed by zone ID."
  value       = { for zone_id, nat_gateway in alicloud_nat_gateway.security : zone_id => nat_gateway.id }
}

output "nat_eip_addresses" {
  description = "Security VPC NAT EIP addresses keyed by zone ID."
  value       = { for zone_id, eip in alicloud_eip_address.security_nat : zone_id => eip.ip_address }
}

# CEN
output "cen_id" {
  description = "CEN instance ID."
  value       = local.cen_id
}

output "transit_router_id" {
  description = "Transit Router ID."
  value       = module.cen_tr.id
}

output "transit_router_route_table_ids" {
  description = "Transit Router route table IDs."
  value       = module.cen_tr.route_table_ids
}

output "transit_router_vpc_attachment_ids" {
  description = "Transit Router VPC attachment IDs."
  value       = module.cen_tr.vpc_attachment_ids
}
