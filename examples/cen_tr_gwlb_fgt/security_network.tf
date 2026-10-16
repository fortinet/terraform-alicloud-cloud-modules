locals {
  security_zone_vswitches = flatten([
    for zone_id in sort(keys(var.security_vpc.zones)) : concat(
      [
        {
          key  = "${zone_id}/inspection"
          name = "${local.prefix}-security-inspection-${zone_id}"
          zone = zone_id
          cidr = var.security_vpc.zones[zone_id].inspection_vswitch_cidr
        },
        {
          key  = "${zone_id}/tr"
          name = "${local.prefix}-security-tr-${zone_id}"
          zone = zone_id
          cidr = var.security_vpc.zones[zone_id].tr_vswitch_cidr
        },
        {
          key  = "${zone_id}/gwlbe"
          name = "${local.prefix}-security-gwlbe-${zone_id}"
          zone = zone_id
          cidr = var.security_vpc.zones[zone_id].gwlbe_vswitch_cidr
        },
        {
          key  = "${zone_id}/nat"
          name = "${local.prefix}-security-nat-${zone_id}"
          zone = zone_id
          cidr = var.security_vpc.zones[zone_id].nat_vswitch_cidr
        }
      ],
      var.fgt_network_mode == "dual-port" ? [
        {
          key  = "${zone_id}/sync"
          name = "${local.prefix}-security-sync-${zone_id}"
          zone = zone_id
          cidr = var.security_vpc.zones[zone_id].sync_vswitch_cidr
        }
      ] : []
    )
  ])
  security_vswitches = {
    for vswitch in local.security_zone_vswitches : vswitch.key => {
      name = vswitch.name
      zone = vswitch.zone
      cidr = vswitch.cidr
    }
  }
  security_vswitch_ids = {
    for zone_id in keys(var.security_vpc.zones) : zone_id => {
      inspection = module.security_vpc.vswitch_ids_by_zone_cidr["${zone_id}/${var.security_vpc.zones[zone_id].inspection_vswitch_cidr}"]
      tr         = module.security_vpc.vswitch_ids_by_zone_cidr["${zone_id}/${var.security_vpc.zones[zone_id].tr_vswitch_cidr}"]
      gwlbe      = module.security_vpc.vswitch_ids_by_zone_cidr["${zone_id}/${var.security_vpc.zones[zone_id].gwlbe_vswitch_cidr}"]
      nat        = module.security_vpc.vswitch_ids_by_zone_cidr["${zone_id}/${var.security_vpc.zones[zone_id].nat_vswitch_cidr}"]
      sync       = var.fgt_network_mode == "dual-port" ? module.security_vpc.vswitch_ids_by_zone_cidr["${zone_id}/${var.security_vpc.zones[zone_id].sync_vswitch_cidr}"] : ""
    }
  }
  security_tr_route_table_ids = {
    for zone_id, route_table in alicloud_route_table.security_tr : zone_id => route_table.id
  }
  security_gwlbe_route_table_ids = {
    for zone_id, route_table in alicloud_route_table.security_gwlbe : zone_id => route_table.id
  }
  security_nat_business_routes = {
    for route in flatten([
      for zone_id in local.selected_zone_ids : [
        for business_key in keys(var.business_vpcs) : {
          key          = "${zone_id}/${business_key}"
          zone_id      = zone_id
          business_key = business_key
        }
      ]
    ]) : route.key => route
  }
  cen_id = var.cen_id != "" ? var.cen_id : alicloud_cen_instance.this[0].id
}

module "security_vpc" {
  source = "../../modules/alicloud/vpc"

  prefix = "${local.prefix}-security"

  vpc = {
    cidr = var.security_vpc.cidr
  }

  vswitch = values(local.security_vswitches)

  security_group = {
    rules = [
      {
        type        = "ingress"
        ip_protocol = "all"
        policy      = "accept"
        cidr_ip     = "0.0.0.0/0"
        description = "Allow inbound traffic for the example."
      },
      {
        type        = "egress"
        ip_protocol = "all"
        policy      = "accept"
        cidr_ip     = "0.0.0.0/0"
        description = "Allow outbound traffic for the example."
      }
    ]
  }

  resource_group_id = var.resource_group_id
  tags              = var.tags
}

resource "alicloud_cen_instance" "this" {
  count = var.cen_id == "" ? 1 : 0

  cen_instance_name = "${local.prefix}-cen"
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

module "cen_tr" {
  source = "../../modules/alicloud/cen-tr"

  prefix = local.prefix
  cen_id = local.cen_id

  route_tables = {
    business_egress = {
      description = "Routes business VPC egress traffic to the Security VPC attachment."
    }
    security_return = {
      description = "Routes inspected return traffic from the Security VPC back to business VPC attachments."
    }
  }

  vpc_attachments = merge(
    {
      security = {
        vpc_id = module.security_vpc.vpc_id
        zone_mappings = [
          for zone_id in sort(keys(local.security_vswitch_ids)) : {
            zone_id    = zone_id
            vswitch_id = local.security_vswitch_ids[zone_id].tr
          }
        ]
        options = var.security_attachment_appliance_mode_support == null ? null : {
          appliance_mode_support = var.security_attachment_appliance_mode_support
        }
      }
    },
    {
      for business_key, business_vpc in var.business_vpcs : business_key => {
        vpc_id = business_vpc.vpc_id
        zone_mappings = [
          for zone_id in sort(keys(local.business_tr_vswitch_ids[business_key])) : {
            zone_id    = zone_id
            vswitch_id = local.business_tr_vswitch_ids[business_key][zone_id]
          }
        ]
      }
    }
  )

  route_table_associations = merge(
    {
      security = {
        route_table_key = "security_return"
        attachment_key  = "security"
      }
    },
    {
      for business_key in keys(var.business_vpcs) : business_key => {
        route_table_key = "business_egress"
        attachment_key  = business_key
      }
    }
  )

  route_entries = merge(
    {
      default_to_security = {
        route_table_key         = "business_egress"
        destination_cidr_block  = "0.0.0.0/0"
        next_hop_type           = "Attachment"
        next_hop_attachment_key = "security"
        description             = "Send business default traffic to the Security VPC."
      }
    },
    {
      for business_key, business_vpc in var.business_vpcs : "return_to_${business_key}" => {
        route_table_key         = "security_return"
        destination_cidr_block  = business_vpc.cidr
        next_hop_type           = "Attachment"
        next_hop_attachment_key = business_key
        description             = "Return inspected traffic to the business VPC attachment."
      }
    }
  )

  tags = var.tags
}

resource "alicloud_route_table" "security_tr" {
  for_each = local.security_vswitch_ids

  vpc_id           = module.security_vpc.vpc_id
  route_table_name = "${local.prefix}-security-tr-rt-${each.key}"
  description      = "Routes traffic from this Transit Router attachment VSwitch to its same-zone GWLBe."
}

resource "alicloud_route_table_attachment" "security_tr" {
  for_each = local.security_vswitch_ids

  vswitch_id     = each.value.tr
  route_table_id = local.security_tr_route_table_ids[each.key]
}

resource "alicloud_route_table" "security_gwlbe" {
  for_each = local.security_vswitch_ids

  vpc_id           = module.security_vpc.vpc_id
  route_table_name = "${local.prefix}-security-gwlbe-rt-${each.key}"
  description      = "Routes inspected egress traffic to NAT and return traffic to CEN Transit Router in this zone."
}

resource "alicloud_route_table_attachment" "security_gwlbe" {
  for_each = local.security_vswitch_ids

  vswitch_id     = each.value.gwlbe
  route_table_id = local.security_gwlbe_route_table_ids[each.key]
}

resource "alicloud_route_table" "security_inspection" {
  for_each = local.security_vswitch_ids

  vpc_id           = module.security_vpc.vpc_id
  route_table_name = "${local.prefix}-security-inspection-rt-${each.key}"
  description      = "Routes FortiGate management egress to the same-zone NAT Gateway."
}

resource "alicloud_route_table_attachment" "security_inspection" {
  for_each = local.security_vswitch_ids

  vswitch_id     = each.value.inspection
  route_table_id = alicloud_route_table.security_inspection[each.key].id

  depends_on = [
    alicloud_route_entry.inspection_to_nat,
    alicloud_snat_entry.inspection,
  ]
}

resource "alicloud_route_entry" "inspection_to_nat" {
  for_each = local.security_vswitch_ids

  route_table_id        = alicloud_route_table.security_inspection[each.key].id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type          = "NatGateway"
  nexthop_id            = alicloud_nat_gateway.security[each.key].id
  name                  = "${local.prefix}-inspection-to-nat-${each.key}"
}

resource "alicloud_route_table" "security_nat" {
  for_each = local.security_vswitch_ids

  vpc_id           = module.security_vpc.vpc_id
  route_table_name = "${local.prefix}-security-nat-rt-${each.key}"
  description      = "Routes NAT return traffic to the same-zone GWLBe before returning to business VPCs."
}

resource "alicloud_route_table_attachment" "security_nat" {
  for_each = local.security_vswitch_ids

  vswitch_id     = each.value.nat
  route_table_id = alicloud_route_table.security_nat[each.key].id
}

resource "alicloud_nat_gateway" "security" {
  for_each = local.security_vswitch_ids

  vpc_id            = module.security_vpc.vpc_id
  vswitch_id        = each.value.nat
  nat_gateway_name  = "${local.prefix}-security-nat-${each.key}"
  nat_type          = "Enhanced"
  availability_mode = "CrossAZ"
  tags              = var.tags
}

resource "alicloud_eip_address" "security_nat" {
  for_each = local.security_vswitch_ids

  address_name      = "${local.prefix}-security-nat-eip-${each.key}"
  bandwidth         = tostring(var.outbound_bandwidth)
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

resource "alicloud_eip_association" "security_nat" {
  for_each = local.security_vswitch_ids

  allocation_id = alicloud_eip_address.security_nat[each.key].id
  instance_id   = alicloud_nat_gateway.security[each.key].id
}

resource "alicloud_snat_entry" "inspection" {
  for_each = local.security_vswitch_ids

  snat_table_id     = alicloud_nat_gateway.security[each.key].snat_table_ids
  source_vswitch_id = each.value.inspection
  snat_ip           = alicloud_eip_address.security_nat[each.key].ip_address

  depends_on = [alicloud_eip_association.security_nat]
}

resource "alicloud_snat_entry" "business" {
  for_each = local.security_nat_business_routes

  snat_table_id = alicloud_nat_gateway.security[each.value.zone_id].snat_table_ids
  source_cidr   = var.business_vpcs[each.value.business_key].cidr
  snat_ip       = alicloud_eip_address.security_nat[each.value.zone_id].ip_address

  depends_on = [
    alicloud_eip_association.security_nat
  ]
}

resource "alicloud_route_entry" "gwlbe_to_nat" {
  for_each = local.security_vswitch_ids

  route_table_id        = local.security_gwlbe_route_table_ids[each.key]
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type          = "NatGateway"
  nexthop_id            = alicloud_nat_gateway.security[each.key].id
  name                  = "${local.prefix}-gwlbe-to-nat-${each.key}"
}

resource "alicloud_route_entry" "gwlbe_to_tr" {
  for_each = local.security_nat_business_routes

  route_table_id        = local.security_gwlbe_route_table_ids[each.value.zone_id]
  destination_cidrblock = var.business_vpcs[each.value.business_key].cidr
  nexthop_type          = "Attachment"
  nexthop_id            = module.cen_tr.vpc_attachment_ids.security
  name                  = "${local.prefix}-gwlbe-to-tr-${each.value.zone_id}-${each.value.business_key}"
}

resource "alicloud_route_entry" "nat_to_gwlbe" {
  for_each = local.security_nat_business_routes

  route_table_id        = alicloud_route_table.security_nat[each.value.zone_id].id
  destination_cidrblock = var.business_vpcs[each.value.business_key].cidr
  nexthop_type          = "GatewayLoadBalancerEndpoint"
  nexthop_id            = module.gwlbe.endpoint_ids[each.value.zone_id]
  name                  = "${local.prefix}-nat-to-gwlbe-${each.value.zone_id}-${each.value.business_key}"
}
