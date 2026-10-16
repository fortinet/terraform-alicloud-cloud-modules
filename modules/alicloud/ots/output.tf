output "id" {
  description = "OTS instance ID."
  value       = try(alicloud_ots_instance.database[0].id, null)
}

output "name" {
  description = "OTS instance name."
  value       = local.instance_name
}

output "instance_type" {
  description = "OTS instance type."
  value       = local.create_instance ? local.instance_type : null
}

output "table_ids" {
  description = "OTS table IDs."
  value       = { for index, table in alicloud_ots_table.tables : var.tables[tonumber(index)].table_name => table.id }
}

output "table_names" {
  description = "OTS table names."
  value       = [for table in var.tables : table.table_name]
}
