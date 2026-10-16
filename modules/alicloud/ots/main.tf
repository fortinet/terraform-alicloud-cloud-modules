locals {
  ots_region_instance_types = {
    cn-hangzhou           = ["HighPerformance", "Capacity"]
    cn-hangzhou-finance   = ["HighPerformance"]
    cn-shanghai           = ["HighPerformance", "Capacity"]
    cn-shanghai-finance-1 = ["Capacity"]
    cn-qingdao            = ["Capacity"]
    cn-beijing            = ["HighPerformance", "Capacity"]
    cn-zhangjiakou        = ["HighPerformance", "Capacity"]
    cn-huhehaote          = ["Capacity"]
    cn-wulanchabu         = ["HighPerformance"]
    cn-shenzhen           = ["HighPerformance", "Capacity"]
    cn-guangzhou          = ["HighPerformance"]
    cn-chengdu            = ["HighPerformance", "Capacity"]
    cn-hongkong           = ["HighPerformance", "Capacity"]
    ap-southeast-1        = ["HighPerformance"]
    ap-southeast-3        = ["HighPerformance", "Capacity"]
    ap-southeast-5        = ["HighPerformance", "Capacity"]
    ap-northeast-1        = ["Capacity"]
    ap-southeast-6        = ["HighPerformance"]
    ap-southeast-7        = ["HighPerformance"]
    eu-central-1          = ["HighPerformance", "Capacity"]
    eu-west-1             = ["HighPerformance", "Capacity"]
    us-west-1             = ["HighPerformance"]
    us-east-1             = ["HighPerformance", "Capacity"]
    me-east-1             = ["Capacity"]
    me-central-1          = ["HighPerformance"]
  }

  supported_instance_types = lookup(local.ots_region_instance_types, var.region, ["Capacity"])
  instance_type            = var.instance_type != null ? var.instance_type : contains(local.supported_instance_types, "HighPerformance") ? "HighPerformance" : "Capacity"
  create_instance          = var.existing_instance_name == ""
  instance_name            = local.create_instance ? var.name : var.existing_instance_name
}

resource "alicloud_ots_instance" "database" {
  count = local.create_instance ? 1 : 0

  name              = var.name
  instance_type     = local.instance_type
  description       = var.description
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

resource "alicloud_ots_table" "tables" {
  for_each = {
    for index, table in var.tables : tostring(index) => table
  }

  instance_name = local.instance_name
  table_name    = each.value.table_name
  time_to_live  = each.value.time_to_live
  max_version   = each.value.max_version

  dynamic "primary_key" {
    for_each = each.value.primary_key
    content {
      name = primary_key.value.name
      type = primary_key.value.type
    }
  }

  dynamic "defined_column" {
    for_each = each.value.defined_column
    content {
      name = defined_column.value.name
      type = defined_column.value.type
    }
  }

  depends_on = [alicloud_ots_instance.database]
}
