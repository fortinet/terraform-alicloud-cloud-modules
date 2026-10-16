locals {
  addresses = flatten([
    for mapping in alicloud_gwlb_load_balancer.this.zone_mappings : [
      for address in mapping.load_balancer_addresses : {
        eni_id               = address.eni_id
        private_ipv4_address = address.private_ipv4_address
      }
    ]
  ])
  addresses_by_zone = {
    for mapping in alicloud_gwlb_load_balancer.this.zone_mappings : mapping.zone_id => try(mapping.load_balancer_addresses[0].private_ipv4_address, "")
  }
}

resource "alicloud_gwlb_load_balancer" "this" {
  vpc_id             = var.vpc_id
  load_balancer_name = "${var.prefix}-gwlb"
  dynamic "zone_mappings" {
    for_each = var.zone_mappings
    content {
      zone_id    = zone_mappings.value.zone_id
      vswitch_id = zone_mappings.value.vswitch_id
    }
  }
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

resource "alicloud_gwlb_server_group" "this" {
  server_group_name    = "${var.prefix}-gwlb-sg"
  server_group_type    = "Instance"
  vpc_id               = var.vpc_id
  protocol             = "GENEVE"
  scheduler            = "5TCH"
  server_failover_mode = "Rebalance"

  health_check_config {
    health_check_enabled         = var.health_check.health_check_enabled
    health_check_protocol        = var.health_check.health_check_protocol
    health_check_connect_port    = var.health_check.health_check_connect_port
    health_check_connect_timeout = var.health_check.health_check_connect_timeout
    health_check_interval        = var.health_check.health_check_interval
    healthy_threshold            = var.health_check.healthy_threshold
    unhealthy_threshold          = var.health_check.unhealthy_threshold
  }

  connection_drain_config {
    connection_drain_enabled = var.health_check.connection_drain_enabled
    connection_drain_timeout = var.health_check.connection_drain_timeout
  }
  resource_group_id = var.resource_group_id
  tags              = var.tags

  lifecycle {
    ignore_changes = [
      servers
    ]
  }
}

resource "alicloud_gwlb_listener" "this" {
  listener_description = "${var.prefix}-gwlb-listener"

  server_group_id  = alicloud_gwlb_server_group.this.id
  load_balancer_id = alicloud_gwlb_load_balancer.this.id
  tags             = var.tags
}
