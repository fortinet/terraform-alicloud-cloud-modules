locals {
  prefix = "${var.prefix}-"
  vswitches_by_zone_cidr = {
    for vswitch in var.vswitch : "${vswitch.zone}/${vswitch.cidr}" => vswitch
  }
}

resource "alicloud_vpc" "vpc" {
  vpc_name          = var.vpc.name != "" ? var.vpc.name : "${local.prefix}vpc"
  description       = var.vpc.description
  cidr_block        = var.vpc.cidr
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

resource "alicloud_vswitch" "vswitch" {
  for_each     = local.vswitches_by_zone_cidr
  vswitch_name = each.value.name != "" ? each.value.name : "${local.prefix}vswitch-${each.value.zone}-${each.value.cidr}"
  description  = each.value.description
  cidr_block   = each.value.cidr
  vpc_id       = alicloud_vpc.vpc.id
  zone_id      = each.value.zone
  tags         = var.tags
}

resource "alicloud_security_group" "security_group" {
  security_group_name = var.security_group.name != "" ? var.security_group.name : "${local.prefix}security-group"
  description         = var.security_group.description
  vpc_id              = alicloud_vpc.vpc.id
  resource_group_id   = var.resource_group_id
  tags                = var.tags
}

resource "alicloud_security_group_rule" "security_group_rules" {
  count             = length(var.security_group.rules)
  security_group_id = alicloud_security_group.security_group.id
  type              = var.security_group.rules[count.index].type
  description       = var.security_group.rules[count.index].description
  ip_protocol       = var.security_group.rules[count.index].ip_protocol
  nic_type          = "intranet"
  policy            = var.security_group.rules[count.index].policy
  port_range        = var.security_group.rules[count.index].port_range
  priority          = var.security_group.rules[count.index].priority
  cidr_ip           = var.security_group.rules[count.index].cidr_ip
}
