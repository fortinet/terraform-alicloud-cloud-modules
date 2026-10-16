output "endpoint_ids" {
  description = "GWLBe endpoint IDs keyed by zone ID."
  value       = { for key, zone in alicloud_privatelink_vpc_endpoint_zone.this : key => zone.endpoint_id }
}

output "endpoint_zones" {
  description = "GWLBe endpoint zone resources keyed by zone ID."
  value       = alicloud_privatelink_vpc_endpoint_zone.this
}

output "route_entry_ids" {
  description = "Route entry IDs keyed by the stable names supplied in route_entries."
  value       = { for key, route in alicloud_route_entry.app_to_gwlbe : key => route.id }
}
