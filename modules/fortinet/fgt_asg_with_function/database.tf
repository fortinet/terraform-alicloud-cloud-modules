locals {
  generated_ots_instance_name = !local.deploy_function || local.use_existing_ots_table ? null : length("${local.resource_prefix}ots") <= 15 ? "${local.resource_prefix}ots" : "${substr(local.resource_prefix, 0, 6)}-${random_string.bucket_suffix[0].result}"
  use_existing_ots_table      = var.function_compute.use_existing_ots_table || var.function_compute.ots_table_name != ""
  ots_instance_name           = !local.deploy_function ? null : local.use_existing_ots_table ? var.function_compute.ots_instance_name : module.autoscale_ots[0].name
  ots_table_name              = !local.deploy_function ? null : local.use_existing_ots_table ? var.function_compute.ots_table_name : "${replace(local.resource_prefix, "-", "_")}database"
}


module "autoscale_ots" {
  count  = local.deploy_function && !local.use_existing_ots_table ? 1 : 0
  source = "../../alicloud/ots"

  name                   = local.generated_ots_instance_name
  existing_instance_name = var.function_compute.ots_instance_name
  region                 = var.region
  description            = "State store for autoscale metadata."
  tables = [
    {
      table_name = local.ots_table_name
      primary_key = [
        {
          name = "ID"
          type = "String"
        }
      ]
    }
  ]
  resource_group_id = var.resource_group_id
  tags              = var.tags
}
