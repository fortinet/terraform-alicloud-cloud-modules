locals {
  business_tr_vswitch_config_list = flatten([
    for business_key, business_vpc in var.business_vpcs : [
      for zone_id, tr_vswitch in business_vpc.tr_vswitches : {
        key          = "${business_key}/${zone_id}"
        business_key = business_key
        zone_id      = zone_id
        vpc_id       = business_vpc.vpc_id
        vswitch_id   = tr_vswitch.vswitch_id
        cidr         = tr_vswitch.cidr
      }
    ]
  ])
  business_tr_vswitch_configs = {
    for config in local.business_tr_vswitch_config_list : config.key => config
  }
  business_tr_vswitch_ids = {
    for business_key, business_vpc in var.business_vpcs : business_key => {
      for zone_id, tr_vswitch in business_vpc.tr_vswitches : zone_id => tr_vswitch.vswitch_id != "" ? tr_vswitch.vswitch_id : alicloud_vswitch.business_tr["${business_key}/${zone_id}"].id
    }
  }
  business_workload_vswitch_list = flatten([
    for business_key, business_vpc in var.business_vpcs : [
      for vswitch_id in sort(tolist(business_vpc.workload_vswitch_ids)) : {
        key          = "${business_key}/${vswitch_id}"
        business_key = business_key
        vswitch_id   = vswitch_id
      }
    ]
  ])
  business_workload_vswitches = {
    for config in local.business_workload_vswitch_list : config.key => config
  }
}

resource "alicloud_vswitch" "business_tr" {
  for_each = {
    for key, config in local.business_tr_vswitch_configs : key => config
    if config.vswitch_id == ""
  }

  vswitch_name = "${local.prefix}-${each.value.business_key}-tr-${each.value.zone_id}"
  cidr_block   = each.value.cidr
  vpc_id       = each.value.vpc_id
  zone_id      = each.value.zone_id
  tags         = var.tags
}

resource "alicloud_route_table" "business_workload" {
  for_each = var.business_vpcs

  vpc_id           = each.value.vpc_id
  route_table_name = "${local.prefix}-${each.key}-workload-rt"
  description      = "Routes business workload default traffic to CEN Transit Router."
}

resource "alicloud_route_table_attachment" "business_workload" {
  for_each = local.business_workload_vswitches

  vswitch_id     = each.value.vswitch_id
  route_table_id = alicloud_route_table.business_workload[each.value.business_key].id

  depends_on = [
    alicloud_route_entry.business_default_to_tr,

    module.cen_tr,
    module.gwlb,
    module.gwlbe,
    alicloud_ess_server_group_attachment.gwlb,

    alicloud_route_table_attachment.security_tr,
    alicloud_route_table_attachment.security_gwlbe,
    alicloud_route_table_attachment.security_nat,

    alicloud_route_entry.gwlbe_to_nat,
    alicloud_route_entry.gwlbe_to_tr,
    alicloud_route_entry.nat_to_gwlbe,
    alicloud_snat_entry.business,
  ]
}

resource "alicloud_route_entry" "business_default_to_tr" {
  for_each = var.business_vpcs

  route_table_id        = alicloud_route_table.business_workload[each.key].id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type          = "Attachment"
  nexthop_id            = module.cen_tr.vpc_attachment_ids[each.key]
  name                  = "${local.prefix}-${each.key}-default-to-tr"
}
