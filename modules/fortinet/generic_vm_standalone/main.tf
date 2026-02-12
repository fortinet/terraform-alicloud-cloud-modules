locals {
  prefix             = "${var.prefix}-"
  image_id           = var.image.image_id != "" ? var.image.image_id : data.alicloud_images.image[0].images[0].id
  hostname           = var.hostname != "" ? var.hostname : "${local.prefix}instance"
  config_file_script = var.config.config_file != "" ? file(var.config.config_file) : ""
  config_script      = var.config.config_script != "" ? "${var.config.config_script}\n${local.config_file_script}" : local.config_file_script
}


data "alicloud_images" "image" {
  count       = var.image.image_id != "" ? 0 : 1
  owners      = "marketplace"
  most_recent = true
  name_regex  = "^Fortinet ${var.image.product_type}.*(${var.image.license_type}).*${var.image.version}"
}

data "template_file" "cloudinit_config" {
  template = file("${path.module}/bootstrap.conf")
  vars = {
    hostname        = local.hostname,
    password        = var.password,
    config_script   = local.config_script
    license_file    = var.license.license_file,
    fortiflex_token = var.license.fortiflex_token,
  }
}

resource "alicloud_instance" "instance" {
  # Instance
  instance_name = local.hostname
  instance_type = var.instance_type
  image_id      = local.image_id
  description   = var.description

  # Network
  vswitch_id      = var.network_interfaces[0].vswitch_id
  security_groups = var.network_interfaces[0].security_group_list
  private_ip      = var.network_interfaces[0].private_ip

  # System Disk
  system_disk_name              = var.system_disk.name != "" ? var.system_disk.name : "${local.prefix}system-disk"
  system_disk_description       = var.system_disk.description != "" ? var.system_disk.description : null
  system_disk_category          = var.system_disk.category
  system_disk_size              = var.system_disk.size
  system_disk_performance_level = var.system_disk.performance_level

  # Data Disk
  dynamic "data_disks" {
    for_each = var.data_disks
    content {
      name              = data_disks.value.name != "" ? data_disks.value.name : "${local.prefix}data-disk-${data_disks.key + 1}"
      description       = data_disks.value.description != "" ? data_disks.value.description : null
      size              = data_disks.value.size
      category          = data_disks.value.category
      performance_level = data_disks.value.performance_level
    }
  }

  # Others
  internet_max_bandwidth_out = var.internet_max_bandwidth_out
  instance_charge_type       = var.instance_charge_type

  user_data         = data.template_file.cloudinit_config.rendered
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

# Extra Interfaces
resource "alicloud_network_interface" "interfaces" {
  count                  = length(var.network_interfaces) > 1 ? length(var.network_interfaces) - 1 : 0
  network_interface_name = "${local.prefix}extra-interface-${count.index + 1}"
  vswitch_id             = var.network_interfaces[count.index+1].vswitch_id
  security_group_ids     = var.network_interfaces[count.index+1].security_group_list
  primary_ip_address     = var.network_interfaces[count.index+1].private_ip
  tags                   = var.tags
  resource_group_id      = var.resource_group_id
}

resource "alicloud_network_interface_attachment" "eni_attach" {
  count                = length(alicloud_network_interface.interfaces)
  instance_id          = alicloud_instance.instance.id
  network_interface_id = alicloud_network_interface.interfaces[count.index].id
}
