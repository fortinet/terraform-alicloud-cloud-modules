locals {
  fgt_password        = var.fgt_password != "" ? var.fgt_password : random_password.fgt_password[0].result
  autoscale_psksecret = var.autoscale_psksecret != "" ? var.autoscale_psksecret : random_password.autoscale_psksecret[0].result
  ots_instance_name   = "${substr(var.prefix, 0, 6)}-${random_string.prefix_suffix.result}-ots"
  ots_table_name      = "${replace(local.prefix, "-", "_")}_table"
}

resource "random_password" "fgt_password" {
  count            = var.fgt_password == "" ? 1 : 0
  length           = 16
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#$%^&*()"
}

resource "random_password" "autoscale_psksecret" {
  count   = var.autoscale_psksecret == "" ? 1 : 0
  length  = 16
  special = false
}

module "autoscale_ots" {
  count  = local.deploy_any_function ? 1 : 0
  source = "../../modules/alicloud/ots"

  name                   = local.ots_instance_name
  existing_instance_name = var.ots_instance_name
  region                 = var.region
  description            = "Shared state store for FortiGate autoscale lifecycle functions."
  tables = [{
    table_name = local.ots_table_name
    primary_key = [{
      name = "ID"
      type = "String"
    }]
  }]
  resource_group_id = var.resource_group_id
  tags              = var.tags
}
