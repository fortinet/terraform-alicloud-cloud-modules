locals {
  supported_instance_types = [
    "ecs.c9i.large",
    "ecs.c9i.xlarge",
    "ecs.c9i.2xlarge",
    "ecs.c9i.4xlarge",
    "ecs.c9i.8xlarge",
    "ecs.c7.large",
    "ecs.c7.xlarge",
    "ecs.c7.2xlarge",
    "ecs.c7.4xlarge",
    "ecs.c7.8xlarge",
    "ecs.c7a.large",
    "ecs.c7a.xlarge",
    "ecs.c7a.2xlarge",
    "ecs.c7a.4xlarge",
    "ecs.c7a.8xlarge",
    "ecs.c6.large",
    "ecs.c6.xlarge",
    "ecs.c6.2xlarge",
    "ecs.c6.4xlarge",
    "ecs.c6.8xlarge",
    "ecs.c5.large",
    "ecs.c5.xlarge",
    "ecs.c5.2xlarge",
    "ecs.c5.4xlarge",
    "ecs.c5.8xlarge",
    "ecs.sn1ne.large",
    "ecs.sn1ne.xlarge",
    "ecs.sn1ne.2xlarge",
    "ecs.sn1ne.4xlarge",
    "ecs.sn1ne.8xlarge",
    "ecs.g9i.large",
    "ecs.g9i.xlarge",
    "ecs.g9i.2xlarge",
    "ecs.g9i.4xlarge",
    "ecs.g9i.8xlarge",
    "ecs.g8i.large",
    "ecs.g8i.xlarge",
    "ecs.g8i.2xlarge",
    "ecs.g8i.4xlarge",
    "ecs.g8i.8xlarge",
    "ecs.g5ne.large",
    "ecs.g5ne.xlarge",
    "ecs.g5ne.2xlarge",
    "ecs.g5ne.4xlarge",
    "ecs.g5ne.8xlarge",
    "ecs.g7ne.large",
    "ecs.g7ne.xlarge",
    "ecs.g7ne.2xlarge",
    "ecs.g7ne.4xlarge",
    "ecs.g7ne.8xlarge",
    "ecs.hfc5.large",
    "ecs.hfc5.xlarge",
    "ecs.hfc5.2xlarge",
    "ecs.hfc5.4xlarge",
    "ecs.hfc5.8xlarge",
    "ecs.hfc6.large",
    "ecs.hfc6.xlarge",
    "ecs.hfc6.2xlarge",
    "ecs.hfc6.4xlarge",
    "ecs.hfc6.8xlarge",
    "ecs.sn1.medium",
    "ecs.sn1.large",
    "ecs.sn1.xlarge",
    "ecs.sn1.3xlarge",
    "ecs.sn1.7xlarge",
  ]
  instance_type_details = {
    for instance_type in data.alicloud_instance_types.fgt.instance_types : instance_type.id => instance_type
  }
  selected_zones = toset(keys(local.primary_interface.vswitch_ids))
  available_supported_instance_types = [
    for instance_type in local.supported_instance_types : instance_type
    if contains(data.alicloud_instance_types.fgt.ids, instance_type) && length(setsubtract(
      local.selected_zones,
      toset(try(local.instance_type_details[instance_type].availability_zones, []))
    )) == 0
  ]
  instance_type = var.instance_type != "" ? var.instance_type : try(local.available_supported_instance_types[0], "")
}

data "alicloud_instance_types" "fgt" {
  instance_charge_type = "PostPaid"
  network_type         = "Vpc"
  eni_amount           = local.interface_count
  system_disk_category = var.system_disk.category
  image_id             = local.image_id
  instance_type        = var.instance_type != "" ? var.instance_type : null
}
