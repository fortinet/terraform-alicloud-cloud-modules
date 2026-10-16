locals {
  resource_prefix   = "${var.prefix}-"
  interface_count   = length(var.network.interfaces)
  interface_names   = [for port_number in range(1, local.interface_count + 1) : "port${port_number}"]
  primary_interface = var.network.interfaces["port1"]
  ha_sync_interface = var.network.ha_sync_interface != "" ? var.network.ha_sync_interface : local.interface_count == 1 ? "port1" : "port2"
  secondary_interfaces = {
    for interface_name, interface in var.network.interfaces : interface_name => {
      security_group_id = interface.security_group_id
      vswitch_ids       = interface.vswitch_ids
      route_cidrs       = interface.route_cidrs
    } if interface_name != "port1"
  }
  image_id            = var.image.image_id != "" ? var.image.image_id : data.alicloud_images.fgt[0].images[0].id
  hostname            = var.fgt_hostname != "" ? var.fgt_hostname : "${local.resource_prefix}fgt"
  fgt_password        = var.fgt_password
  autoscale_psksecret = var.function_compute.autoscale_psksecret
  config_file_script  = var.config_file != "" ? file(var.config_file) : ""
  config_script       = var.config_script != "" ? "${var.config_script}\n${local.config_file_script}" : local.config_file_script
}

data "alicloud_account" "current" {}

data "alicloud_images" "fgt" {
  count       = var.image.image_id != "" ? 0 : 1
  owners      = "marketplace"
  most_recent = true
  name_regex  = "^Fortinet ${var.image.product_type}.*(${var.image.license_type}).*${var.image.version}"
}

resource "alicloud_ess_scaling_configuration" "fgt" {
  scaling_group_id           = alicloud_ess_scaling_group.fgt.id
  scaling_configuration_name = "${local.resource_prefix}configuration"
  instance_description       = "${var.prefix} FortiGate autoscale instance"
  image_id                   = local.image_id
  host_name                  = local.hostname
  instance_name              = "${local.resource_prefix}fgt"
  instance_type              = local.instance_type
  security_group_id          = local.primary_interface.security_group_id
  internet_max_bandwidth_out = var.network.internet_bandwidth
  user_data = base64encode(templatefile("${path.module}/bootstrap.conf", {
    hostname      = local.hostname
    config_script = local.config_script
    port1_routes = [for cidr in local.primary_interface.route_cidrs : {
      network = cidrhost(cidr, 0)
      netmask = cidrnetmask(cidr)
    }]
    health_check_port = var.health_check_port
  }))
  system_disk_name              = var.system_disk.name != "" ? var.system_disk.name : "${local.resource_prefix}system-disk"
  system_disk_category          = var.system_disk.category
  system_disk_size              = var.system_disk.size
  system_disk_description       = var.system_disk.description != "" ? var.system_disk.description : null
  system_disk_performance_level = var.system_disk.performance_level

  dynamic "data_disk" {
    for_each = var.data_disks
    content {
      name                 = data_disk.value.name != "" ? data_disk.value.name : "${local.resource_prefix}data-disk-${data_disk.key + 1}"
      description          = data_disk.value.description != "" ? data_disk.value.description : null
      size                 = data_disk.value.size
      category             = data_disk.value.category
      performance_level    = data_disk.value.performance_level
      delete_with_instance = true
    }
  }
  resource_group_id = var.resource_group_id
  tags              = var.tags

  active       = true
  enable       = true
  force_delete = true

  # Enable the group only after the complete lifecycle notification path exists.
  depends_on = [
    alicloud_ess_lifecycle_hook.scale_out,
    alicloud_ess_lifecycle_hook.scale_in
  ]

  lifecycle {
    # Keep a replacement available before deleting the active configuration.
    create_before_destroy = true

    precondition {
      condition     = local.instance_type != ""
      error_message = "No FortiGate-supported Alicloud ECS instance type is available in every configured zone for the selected image, charge type, network type, system disk category, and interface count. Set instance_type explicitly or adjust the filters."
    }
    precondition {
      condition     = var.instance_type == "" || contains(local.supported_instance_types, var.instance_type)
      error_message = "instance_type is not in the FortiGate-supported Alicloud ECS instance type list."
    }
    precondition {
      condition = var.instance_type == "" ? true : (
        contains(data.alicloud_instance_types.fgt.ids, var.instance_type) &&
        length(setsubtract(local.selected_zones, toset(try(local.instance_type_details[var.instance_type].availability_zones, [])))) == 0
      )
      error_message = "instance_type must be available in every zone configured by network.interfaces.port1.vswitch_ids and support the configured interface count."
    }
  }
}
