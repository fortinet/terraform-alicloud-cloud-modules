locals {
  prefix                      = "${var.prefix}-"
  transit_router_id           = alicloud_cen_transit_router.this.transit_router_id
  transit_router_route_tables = { for name, route_table in alicloud_cen_transit_router_route_table.this : name => route_table.transit_router_route_table_id }
  transit_router_attachments  = { for name, attachment in alicloud_cen_transit_router_vpc_attachment.this : name => attachment.transit_router_attachment_id }
}

resource "alicloud_cen_transit_router" "this" {
  cen_id                     = var.cen_id
  transit_router_name        = var.name != "" ? var.name : "${local.prefix}tr"
  transit_router_description = var.description
  support_multicast          = var.support_multicast
  tags                       = var.tags
}

resource "alicloud_cen_transit_router_route_table" "this" {
  for_each = var.route_tables

  transit_router_id                      = local.transit_router_id
  transit_router_route_table_name        = each.value.name != "" ? each.value.name : "${local.prefix}${each.key}"
  transit_router_route_table_description = each.value.description
  tags                                   = var.tags
}

resource "alicloud_cen_transit_router_vpc_attachment" "this" {
  for_each = var.vpc_attachments

  cen_id                                = var.cen_id
  transit_router_id                     = local.transit_router_id
  vpc_id                                = each.value.vpc_id
  resource_type                         = "VPC"
  transit_router_vpc_attachment_name    = each.value.name != "" ? each.value.name : "${local.prefix}${each.key}"
  transit_router_attachment_description = each.value.description
  auto_publish_route_enabled            = each.value.auto_publish_route_enabled
  force_delete                          = each.value.force_delete
  order_type                            = each.value.order_type
  payment_type                          = each.value.payment_type
  tags                                  = var.tags

  dynamic "zone_mappings" {
    for_each = each.value.zone_mappings
    content {
      zone_id    = zone_mappings.value.zone_id
      vswitch_id = zone_mappings.value.vswitch_id
    }
  }

  dynamic "options" {
    for_each = each.value.options == null ? [] : [each.value.options]
    content {
      appliance_mode_support = options.value.appliance_mode_support
      ipv6_support           = options.value.ipv6_support
    }
  }
}

resource "alicloud_cen_transit_router_route_table_association" "this" {
  for_each = var.route_table_associations

  transit_router_route_table_id = each.value.route_table_id != "" ? each.value.route_table_id : local.transit_router_route_tables[each.value.route_table_key]
  transit_router_attachment_id  = each.value.attachment_id != "" ? each.value.attachment_id : local.transit_router_attachments[each.value.attachment_key]
}

resource "alicloud_cen_transit_router_route_table_propagation" "this" {
  for_each = var.route_table_propagations

  transit_router_route_table_id = each.value.route_table_id != "" ? each.value.route_table_id : local.transit_router_route_tables[each.value.route_table_key]
  transit_router_attachment_id  = each.value.attachment_id != "" ? each.value.attachment_id : local.transit_router_attachments[each.value.attachment_key]
}

resource "alicloud_cen_transit_router_route_entry" "this" {
  for_each = var.route_entries

  transit_router_route_table_id                     = each.value.route_table_id != "" ? each.value.route_table_id : local.transit_router_route_tables[each.value.route_table_key]
  transit_router_route_entry_destination_cidr_block = each.value.destination_cidr_block
  transit_router_route_entry_next_hop_type          = each.value.next_hop_type
  transit_router_route_entry_next_hop_id            = each.value.next_hop_id != "" ? each.value.next_hop_id : each.value.next_hop_attachment_key != "" ? local.transit_router_attachments[each.value.next_hop_attachment_key] : null
  transit_router_route_entry_name                   = each.value.name != "" ? each.value.name : "${local.prefix}${each.key}"
  transit_router_route_entry_description            = each.value.description
}
