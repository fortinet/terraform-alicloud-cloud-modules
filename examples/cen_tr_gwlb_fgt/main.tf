data "alicloud_gwlb_zones" "available" {}

data "alicloud_cen_transit_router_available_resources" "available" {}

data "alicloud_fc_zones" "available" {
  count = local.deploy_any_function ? 1 : 0
}

data "alicloud_enhanced_nat_available_zones" "available" {}

locals {
  prefix    = "${var.prefix}-${random_string.prefix_suffix.result}"
  asg_names = nonsensitive(toset(keys(var.fortigate_asgs)))
  deploy_any_function = nonsensitive(anytrue([
    for group in values(var.fortigate_asgs) : group.function_compute.deploy_function
  ]))
  selected_zone_ids = sort(keys(var.security_vpc.zones))
  gwlb_tunnels = [
    for zone_id in local.selected_zone_ids : {
      name      = "gwlb-${substr(sha256(zone_id), 0, 8)}"
      remote_ip = module.gwlb.addresses_by_zone[zone_id]
    }
  ]
  gwlb_config_script = templatefile("${path.module}/bootstrap.conf", {
    gwlb_tunnels  = local.gwlb_tunnels
    config_script = var.config_script
  })
  cen_available_zone_ids = toset(flatten([
    for resource in data.alicloud_cen_transit_router_available_resources.available.resources : resource.available_zones
  ]))
}

resource "random_string" "prefix_suffix" {
  length  = 4
  lower   = true
  numeric = true
  special = false
  upper   = false

  lifecycle {
    precondition {
      condition     = alltrue([for zone_id in local.selected_zone_ids : startswith(zone_id, var.region)])
      error_message = "Every security_vpc.zones key must belong to the configured region."
    }
    precondition {
      condition     = var.fgt_network_mode != "dual-port" || alltrue([for zone in values(var.security_vpc.zones) : zone.sync_vswitch_cidr != ""])
      error_message = "Every security VPC zone must provide sync_vswitch_cidr in dual-port mode."
    }
    precondition {
      condition = alltrue([
        for group in values(var.fortigate_asgs) :
        !group.function_compute.deploy_function || (
          group.image.license_type == "PAYG" ? group.license.license_source == "none" : group.license.license_source != "none"
        )
      ])
      error_message = "Each group with Function Compute enabled must use license_source none for PAYG or specify a license source for BYOL."
    }
    precondition {
      condition     = var.fgt_network_mode != "dual-port" || alltrue([for group in values(var.fortigate_asgs) : group.function_compute.deploy_function])
      error_message = "Every group must enable function_compute.deploy_function in dual-port mode."
    }
    precondition {
      condition     = length(setsubtract(toset(local.selected_zone_ids), toset(data.alicloud_gwlb_zones.available.ids))) == 0
      error_message = "Every security VPC zone must support Gateway Load Balancer."
    }
    precondition {
      condition     = length(setsubtract(toset(local.selected_zone_ids), local.cen_available_zone_ids)) == 0
      error_message = "Every security VPC zone must support Enterprise Edition Transit Router VPC attachments."
    }
    precondition {
      condition     = !local.deploy_any_function ? true : length(setsubtract(toset(local.selected_zone_ids), toset(data.alicloud_fc_zones.available[0].ids))) == 0
      error_message = "Every security VPC zone must support Function Compute VPC access."
    }
    precondition {
      condition = length(setsubtract(
        toset(local.selected_zone_ids),
        toset([for zone in data.alicloud_enhanced_nat_available_zones.available.zones : zone.zone_id])
      )) == 0
      error_message = "Every security VPC zone must support Enhanced NAT Gateway."
    }
  }
}

module "fortigate_asg" {
  for_each = local.asg_names
  source   = "../../modules/fortinet/fgt_asg_with_function"

  prefix       = "${local.prefix}-${each.key}"
  region       = var.region
  fgt_hostname = var.fortigate_asgs[each.key].fgt_hostname
  fgt_password = local.fgt_password

  instance_type = var.fortigate_asgs[each.key].instance_type
  image         = var.fortigate_asgs[each.key].image
  system_disk   = var.fortigate_asgs[each.key].system_disk
  data_disks    = var.fortigate_asgs[each.key].data_disks

  network = {
    interfaces = merge(
      {
        port1 = {
          vswitch_ids = {
            for zone_id, vswitches in local.security_vswitch_ids : zone_id => vswitches.inspection
          }
          security_group_id = module.security_vpc.security_group_id
          route_cidrs       = [for zone in values(var.security_vpc.zones) : zone.inspection_vswitch_cidr]
        }
      },
      var.fgt_network_mode == "dual-port" ? {
        port2 = {
          vswitch_ids = {
            for zone_id, vswitches in local.security_vswitch_ids : zone_id => vswitches.sync
          }
          security_group_id = module.security_vpc.security_group_id
          route_cidrs       = [for zone in values(var.security_vpc.zones) : zone.sync_vswitch_cidr]
        }
      } : {}
    )
    internet_bandwidth = var.fortigate_asgs[each.key].fgt_has_public_ip ? 10 : 0
  }

  health_check_port = var.health_check.health_check_connect_port

  # Keep deployment controls public while preserving sensitive secrets and environment variables.
  function_compute = {
    deploy_function        = nonsensitive(var.fortigate_asgs[each.key].function_compute.deploy_function)
    logging_level          = nonsensitive(var.fortigate_asgs[each.key].function_compute.logging_level)
    additional_variables   = var.fortigate_asgs[each.key].function_compute.additional_variables
    autoscale_psksecret    = local.autoscale_psksecret
    ots_instance_name      = try(module.autoscale_ots[0].name, "")
    ots_table_name         = nonsensitive(var.fortigate_asgs[each.key].function_compute.deploy_function) ? local.ots_table_name : ""
    use_existing_ots_table = nonsensitive(var.fortigate_asgs[each.key].function_compute.deploy_function)
    vpc_id                 = module.security_vpc.vpc_id
    vswitch_ids = [
      for zone_id in local.selected_zone_ids : local.security_vswitch_ids[zone_id].inspection
    ]
    security_group_id = module.security_vpc.security_group_id
  }
  license = var.fortigate_asgs[each.key].license

  # Capacity and scaling settings contain no credentials.
  autoscaler    = nonsensitive(var.fortigate_asgs[each.key].autoscaler)
  config_script = local.gwlb_config_script
  config_file   = var.config_file

  resource_group_id = var.resource_group_id
  tags              = merge(var.tags, { FortiGateASG = each.key })

  depends_on = [
    module.autoscale_ots,
    alicloud_route_table_attachment.security_inspection,
  ]
}

module "gwlb" {
  source = "../../modules/alicloud/gwlb"

  prefix = local.prefix
  vpc_id = module.security_vpc.vpc_id

  zone_mappings = [
    for zone_id in local.selected_zone_ids : {
      zone_id    = zone_id
      vswitch_id = local.security_vswitch_ids[zone_id].inspection
    }
  ]
  health_check      = var.health_check
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

resource "alicloud_ess_server_group_attachment" "gwlb" {
  for_each         = local.asg_names
  scaling_group_id = module.fortigate_asg[each.key].scaling_group_id
  server_group_id  = module.gwlb.server_group_id
  type             = "GWLB"
  force_attach     = true
  depends_on       = [module.fortigate_asg]
}

resource "alicloud_privatelink_vpc_endpoint_service" "gwlb" {
  service_description    = "${local.prefix}-gwlb-endpoint-service"
  service_resource_type  = "gwlb"
  auto_accept_connection = true
  resource_group_id      = var.resource_group_id
  tags                   = var.tags
}

resource "alicloud_privatelink_vpc_endpoint_service_resource" "gwlb" {
  for_each = toset(local.selected_zone_ids)

  service_id    = alicloud_privatelink_vpc_endpoint_service.gwlb.id
  resource_id   = module.gwlb.id
  resource_type = "gwlb"
  zone_id       = each.value
}

module "gwlbe" {
  source = "../../modules/alicloud/gwlbe"

  prefix     = local.prefix
  vpc_id     = module.security_vpc.vpc_id
  service_id = alicloud_privatelink_vpc_endpoint_service.gwlb.id

  endpoint_zones = {
    for zone_id in local.selected_zone_ids : zone_id => {
      vswitch_id = local.security_vswitch_ids[zone_id].gwlbe
    }
  }

  route_entries = {
    for zone_id in local.selected_zone_ids : "${zone_id}/default" => {
      route_table_id        = local.security_tr_route_table_ids[zone_id]
      destination_cidrblock = "0.0.0.0/0"
      endpoint_zone_key     = zone_id
      name                  = "${local.prefix}-tr-to-gwlbe-${zone_id}"
      description           = "Send traffic from the CEN Transit Router VSwitch to the same-zone GWLBe."
    }
  }

  resource_group_id = var.resource_group_id
  tags              = var.tags

  depends_on = [
    alicloud_privatelink_vpc_endpoint_service_resource.gwlb
  ]
}
