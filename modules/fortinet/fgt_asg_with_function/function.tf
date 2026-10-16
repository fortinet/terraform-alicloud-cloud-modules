locals {
  project_version     = "1.1.0"
  deploy_function     = var.function_compute.deploy_function
  function_zip_path   = "${path.module}/function_compute.zip"
  function_zip_hash   = local.deploy_function ? filesha256(local.function_zip_path) : ""
  logging_level       = upper(var.function_compute.logging_level)
  enable_function_log = local.deploy_function && local.logging_level != "NONE"
  use_file_licenses   = contains(["file", "file_fortiflex"], var.license.license_source)
  license_files       = local.deploy_function && local.use_file_licenses ? try(fileset(var.license.license_file_folder, "*.lic"), []) : []
  mns_topic_arn       = local.deploy_function ? "acs:mns:${var.region}:${data.alicloud_account.current.id}:topic/${alicloud_message_service_topic.lifecycle[0].topic_name}" : null
  mns_endpoint        = local.deploy_function ? "http://${data.alicloud_account.current.id}.mns.${var.region}.aliyuncs.com" : null
  network_config = {
    interface_names      = local.interface_names
    secondary_interfaces = local.secondary_interfaces
    ha_sync_interface    = local.ha_sync_interface
  }
}

resource "random_string" "bucket_suffix" {
  count   = local.deploy_function ? 1 : 0
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "alicloud_oss_bucket" "bucket" {
  count             = local.deploy_function ? 1 : 0
  bucket            = "${local.resource_prefix}bucket-${random_string.bucket_suffix[0].result}"
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

resource "alicloud_oss_bucket_acl" "bucket" {
  count  = local.deploy_function ? 1 : 0
  bucket = alicloud_oss_bucket.bucket[0].id
  acl    = "private"
}

resource "alicloud_oss_bucket_object" "function_zip" {
  count      = local.deploy_function ? 1 : 0
  bucket     = alicloud_oss_bucket.bucket[0].id
  key        = "function/function_compute-${local.function_zip_hash}.zip"
  source     = local.function_zip_path
  depends_on = [alicloud_oss_bucket_acl.bucket]

  lifecycle {
    create_before_destroy = true
  }
}

resource "alicloud_oss_bucket_object" "licenses" {
  # Only file names are exposed as resource keys; credentials remain sensitive.
  for_each   = nonsensitive(sensitive(local.deploy_function ? toset(local.license_files) : toset([])))
  bucket     = alicloud_oss_bucket.bucket[0].id
  key        = "licenses/${each.value}"
  source     = "${var.license.license_file_folder}/${each.value}"
  depends_on = [alicloud_oss_bucket_acl.bucket]
}

resource "alicloud_message_service_topic" "lifecycle" {
  count            = local.deploy_function ? 1 : 0
  topic_name       = "${local.resource_prefix}topic"
  max_message_size = 65536
  enable_logging   = true
  tags             = var.tags
}

resource "alicloud_log_project" "function" {
  count             = local.enable_function_log ? 1 : 0
  project_name      = "${local.resource_prefix}log-project"
  description       = "Log project for FortiGate autoscale Function Compute."
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

resource "alicloud_log_store" "function" {
  count         = local.enable_function_log ? 1 : 0
  project_name  = alicloud_log_project.function[0].project_name
  logstore_name = "${local.resource_prefix}log-store"
}

resource "alicloud_log_store_index" "function" {
  count    = local.enable_function_log ? 1 : 0
  project  = alicloud_log_project.function[0].project_name
  logstore = alicloud_log_store.function[0].logstore_name

  full_text {
    case_sensitive = false
    token          = " ,;='\"()[]{}?@&<>/:\n\t\r"
  }
}

resource "alicloud_ram_role" "mns_trigger_role" {
  count     = local.deploy_function ? 1 : 0
  role_name = "${local.resource_prefix}mns-trigger-role"
  assume_role_policy_document = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = ["mns.aliyuncs.com"]
      }
    }]
    Version = "1"
  })
  description = "Role used by MNS to invoke the FortiGate autoscale function."
  force       = true
  tags        = var.tags
}

resource "alicloud_ram_role_policy_attachment" "mns_trigger" {
  count       = local.deploy_function ? 1 : 0
  role_name   = alicloud_ram_role.mns_trigger_role[0].role_name
  policy_name = "AliyunMNSNotificationRolePolicy"
  policy_type = "System"
}

resource "alicloud_ram_role" "function_role" {
  count     = local.deploy_function ? 1 : 0
  role_name = "${local.resource_prefix}function-role"
  assume_role_policy_document = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = ["fc.aliyuncs.com"]
      }
    }]
    Version = "1"
  })
  description = "Role used by FortiGate autoscale Function Compute."
  force       = true
  tags        = var.tags
}

resource "alicloud_ram_policy" "function_policy" {
  count       = local.deploy_function ? 1 : 0
  policy_name = "${local.resource_prefix}function-policy"
  policy_document = jsonencode({
    Statement = [
      {
        Action = [
          "ecs:Describe*",
          "ecs:AttachNetworkInterface",
          "ecs:DetachNetworkInterface",
          "ecs:CreateNetworkInterface",
          "ecs:DeleteNetworkInterface",
          "ess:Describe*",
          "ess:CompleteLifecycleAction",
          "ess:RecordLifecycleActionHeartbeat",
          "gwlb:*",
          "mns:PublishMessage",
          "log:GetProject",
          "log:GetLogStore",
          "log:PostLogStoreLogs"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Action = [
          "oss:GetObject",
          "oss:PutObject",
          "oss:DeleteObject",
          "oss:ListObjects"
        ]
        Effect = "Allow"
        Resource = [
          "acs:oss:*:${data.alicloud_account.current.id}:${alicloud_oss_bucket.bucket[0].bucket}",
          "acs:oss:*:${data.alicloud_account.current.id}:${alicloud_oss_bucket.bucket[0].bucket}/*"
        ]
      },
      {
        Action   = ["ots:ListTable"]
        Effect   = "Allow"
        Resource = ["acs:ots:*:${data.alicloud_account.current.id}:instance/${local.ots_instance_name}"]
      },
      {
        Action = [
          "ots:DescribeTable",
          "ots:GetRow",
          "ots:GetRange",
          "ots:BatchGetRow",
          "ots:PutRow",
          "ots:UpdateRow",
          "ots:DeleteRow",
          "ots:BatchWriteRow",
          "ots:StartLocalTransaction",
          "ots:CommitTransaction",
          "ots:AbortTransaction"
        ]
        Effect = "Allow"
        Resource = [
          "acs:ots:${var.region}:${data.alicloud_account.current.id}:instance/${local.ots_instance_name}/table/${local.ots_table_name}"
        ]
      }
    ]
    Version = "1"
  })
  description = "Permissions for FortiGate autoscale Function Compute."
  force       = true
  tags        = var.tags
}

resource "alicloud_ram_role_policy_attachment" "function_attachment" {
  count       = local.deploy_function ? 1 : 0
  role_name   = alicloud_ram_role.function_role[0].role_name
  policy_name = alicloud_ram_policy.function_policy[0].policy_name
  policy_type = "Custom"
}

resource "alicloud_fcv3_function" "function" {
  count           = local.deploy_function ? 1 : 0
  function_name   = "${local.resource_prefix}function"
  description     = "FortiGate autoscale lifecycle handler."
  role            = alicloud_ram_role.function_role[0].arn
  cpu             = 0.5
  memory_size     = 512
  runtime         = "python3.12"
  handler         = "main.handler"
  timeout         = 1200
  disk_size       = 512
  internet_access = true

  # lib environment
  environment_variables = merge(var.function_compute.additional_variables, {
    PROJECT_VERSION         = local.project_version
    PROJECT_PREFIX          = var.prefix
    REGION                  = var.region
    RESOURCE_GROUP_ID       = var.resource_group_id != null ? var.resource_group_id : ""
    LICENSE_SOURCE          = var.license.license_source
    NETWORK_CONFIG          = jsonencode(local.network_config)
    OSS_BUCKET_NAME         = alicloud_oss_bucket.bucket[0].id
    INSTANCE_PASSWORD       = local.fgt_password
    AUTOSCALE_PSKSECRET     = local.autoscale_psksecret
    LOGGING_LEVEL           = local.logging_level
    MNS_TOPIC_NAME          = alicloud_message_service_topic.lifecycle[0].topic_name
    MNS_ENDPOINT            = local.mns_endpoint
    OTS_INSTANCE_NAME       = local.ots_instance_name
    OTS_TABLE_NAME          = local.ots_table_name
    FORTIFLEX_CONFIG        = var.license.fortiflex.config
    FORTIFLEX_USERNAME      = var.license.fortiflex.username
    FORTIFLEX_PASSWORD      = var.license.fortiflex.password
    FORTIFLEX_RETRIEVE_MODE = var.license.fortiflex.retrieve_mode
  })

  code {
    oss_bucket_name = alicloud_oss_bucket.bucket[0].id
    oss_object_name = alicloud_oss_bucket_object.function_zip[0].key
  }

  dynamic "log_config" {
    for_each = local.enable_function_log ? [1] : []
    content {
      project                 = alicloud_log_project.function[0].project_name
      logstore                = alicloud_log_store.function[0].logstore_name
      enable_instance_metrics = true
      enable_request_metrics  = true
      log_begin_rule          = "DefaultRegex"
    }
  }

  # Note: Configuring vpc_config causes Alibaba Cloud to create an ENI for the function in the specified VPC.
  # Alibaba Cloud manages the ENI lifecycle, so the ENI may temporarily prevent Terraform from deleting its vSwitch.
  # If terraform destroy times out, wait for Alibaba Cloud to remove the ENI, then run terraform destroy again.
  vpc_config {
    vpc_id            = var.function_compute.vpc_id
    vswitch_ids       = var.function_compute.vswitch_ids
    security_group_id = var.function_compute.security_group_id
  }

  resource_group_id = var.resource_group_id
  tags              = var.tags

  # lifecycle {
  #   ignore_changes = [
  #     log_config
  #   ]
  # }

  depends_on = [
    module.autoscale_ots,
    alicloud_ram_role_policy_attachment.function_attachment,
    alicloud_oss_bucket_object.licenses,
    alicloud_log_store_index.function
  ]
}

resource "alicloud_fcv3_trigger" "function_trigger" {
  count           = local.deploy_function ? 1 : 0
  trigger_name    = "${local.resource_prefix}function-trigger"
  function_name   = alicloud_fcv3_function.function[0].function_name
  description     = "FortiGate autoscale lifecycle trigger."
  trigger_type    = "mns_topic"
  qualifier       = "LATEST"
  invocation_role = alicloud_ram_role.mns_trigger_role[0].arn
  source_arn = join("", [
    "acs:mns:${var.region}:${data.alicloud_account.current.id}:",
    "/topics/${alicloud_message_service_topic.lifecycle[0].topic_name}"
  ])
  trigger_config = jsonencode({
    filterTag           = ""
    notifyContentFormat = "STREAM"
    notifyStrategy      = "BACKOFF_RETRY"
  })

  depends_on = [alicloud_ram_role_policy_attachment.mns_trigger]
}

resource "alicloud_ess_lifecycle_hook" "scale_out" {
  count                 = local.deploy_function ? 1 : 0
  scaling_group_id      = alicloud_ess_scaling_group.fgt.id
  name                  = "${local.resource_prefix}scale-out"
  lifecycle_transition  = "SCALE_OUT"
  heartbeat_timeout     = 900
  default_result        = "ABANDON"
  notification_arn      = local.mns_topic_arn
  notification_metadata = jsonencode({ transition = "SCALE_OUT" })

  depends_on = [alicloud_fcv3_trigger.function_trigger]
}

resource "alicloud_ess_lifecycle_hook" "scale_in" {
  count                 = local.deploy_function ? 1 : 0
  scaling_group_id      = alicloud_ess_scaling_group.fgt.id
  name                  = "${local.resource_prefix}scale-in"
  lifecycle_transition  = "SCALE_IN"
  heartbeat_timeout     = 900
  default_result        = "CONTINUE"
  notification_arn      = local.mns_topic_arn
  notification_metadata = jsonencode({ transition = "SCALE_IN" })

  depends_on = [alicloud_fcv3_trigger.function_trigger]
}
