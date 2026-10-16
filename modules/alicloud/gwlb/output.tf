output "id" {
  description = "GWLB instance ID."
  value       = alicloud_gwlb_load_balancer.this.id
}

output "address" {
  description = "First GWLB private IPv4 address."
  value       = try(local.addresses[0].private_ipv4_address, "")
}

output "addresses" {
  description = "GWLB private IPv4 addresses and ENI IDs."
  value       = local.addresses
}

output "addresses_by_zone" {
  description = "GWLB private IPv4 address keyed by zone ID."
  value       = local.addresses_by_zone
}

output "zone_mappings" {
  description = "GWLB zone mappings."
  value       = alicloud_gwlb_load_balancer.this.zone_mappings
}

output "server_group_id" {
  description = "GWLB server group ID."
  value       = alicloud_gwlb_server_group.this.id
}

output "listener_id" {
  description = "GWLB listener ID."
  value       = alicloud_gwlb_listener.this.id
}
