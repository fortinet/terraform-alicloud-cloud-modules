output "scaling_group_id" {
  description = "ESS scaling group ID."
  value       = alicloud_ess_scaling_group.fgt.id
}

output "scaling_configuration_id" {
  description = "ESS scaling configuration ID."
  value       = alicloud_ess_scaling_configuration.fgt.id
}

output "cpu_alarm_ids" {
  description = "Native CPU alarm IDs. Empty when autoscaler.enable_scaling is false."
  value       = concat(alicloud_ess_alarm.cpu_high[*].id, alicloud_ess_alarm.cpu_low[*].id)
}

output "scaling_rule_aris" {
  description = "Native scale-out and scale-in rule ARIs. Null values when autoscaler.enable_scaling is false."
  value = {
    scale_out = try(alicloud_ess_scaling_rule.scale_out[0].ari, null)
    scale_in  = try(alicloud_ess_scaling_rule.scale_in[0].ari, null)
  }
}

output "interface_names" {
  description = "Configured FortiGate interface names in device index order."
  value       = local.interface_names
}

output "zones" {
  description = "Zones used by the FortiGate Auto Scaling group."
  value       = sort(keys(local.primary_interface.vswitch_ids))
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

output "image_id" {
  description = "Image ID."
  value       = local.image_id
}

output "oss_bucket_name" {
  description = "OSS bucket for function package and license files."
  value       = try(alicloud_oss_bucket.bucket[0].id, null)
}

output "mns_topic_name" {
  description = "MNS topic name used by lifecycle and async task messages."
  value       = try(alicloud_message_service_topic.lifecycle[0].topic_name, null)
}

output "mns_topic_arn" {
  description = "MNS topic ARN used by lifecycle and async task messages."
  value       = local.mns_topic_arn
}

output "ots_instance_name" {
  description = "Created or reused OTS instance name for autoscale metadata. Null when Function Compute is disabled."
  value       = local.ots_instance_name
}

output "ots_table_name" {
  description = "Created or reused OTS table name for autoscale metadata. Null when Function Compute is disabled."
  value       = local.ots_table_name
}
