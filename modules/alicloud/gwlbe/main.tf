resource "alicloud_privatelink_vpc_endpoint" "this" {
  for_each = var.endpoint_zones

  vpc_endpoint_name = "${var.prefix}-gwlbe-${each.key}"
  vpc_id            = var.vpc_id
  endpoint_type     = "GatewayLoadBalancer"
  service_id        = var.service_id != "" ? var.service_id : null
  service_name      = var.service_name != "" ? var.service_name : null
  resource_group_id = var.resource_group_id
  tags              = var.tags

  lifecycle {
    precondition {
      condition     = var.service_id != "" || var.service_name != ""
      error_message = "Either service_id or service_name must be set."
    }
  }
}

resource "alicloud_privatelink_vpc_endpoint_zone" "this" {
  for_each = var.endpoint_zones

  endpoint_id = alicloud_privatelink_vpc_endpoint.this[each.key].id
  vswitch_id  = each.value.vswitch_id
}

resource "alicloud_route_entry" "app_to_gwlbe" {
  for_each = var.route_entries

  route_table_id        = each.value.route_table_id
  destination_cidrblock = each.value.destination_cidrblock
  nexthop_type          = "GatewayLoadBalancerEndpoint"
  nexthop_id            = alicloud_privatelink_vpc_endpoint_zone.this[each.value.endpoint_zone_key].endpoint_id
  name                  = each.value.name != "" ? each.value.name : null
  description           = each.value.description != "" ? each.value.description : null
}
