output "id" {
  description = "Transit Router ID."
  value       = local.transit_router_id
}

output "route_table_ids" {
  description = "Transit Router route table IDs."
  value       = local.transit_router_route_tables
}

output "attachment_ids" {
  description = "Transit Router attachment IDs."
  value       = local.transit_router_attachments
}

output "vpc_attachment_ids" {
  description = "Transit Router VPC attachment IDs."
  value       = { for name, attachment in alicloud_cen_transit_router_vpc_attachment.this : name => attachment.transit_router_attachment_id }
}

output "route_table_association_ids" {
  description = "Transit Router route table association IDs."
  value       = { for name, association in alicloud_cen_transit_router_route_table_association.this : name => association.id }
}

output "route_table_propagation_ids" {
  description = "Transit Router route table propagation IDs."
  value       = { for name, propagation in alicloud_cen_transit_router_route_table_propagation.this : name => propagation.id }
}

output "route_entry_ids" {
  description = "Transit Router route entry IDs."
  value       = { for name, route in alicloud_cen_transit_router_route_entry.this : name => route.id }
}
