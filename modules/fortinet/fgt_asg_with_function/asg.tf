resource "alicloud_ess_scaling_group" "fgt" {
  # The scaling configuration enables this group after lifecycle hooks are ready.
  scaling_group_name = "${local.resource_prefix}asg"
  min_size           = var.autoscaler.min_instances
  max_size           = var.autoscaler.max_instances
  desired_capacity   = var.autoscaler.desired_capacity
  default_cooldown   = var.autoscaler.cooldown_period
  vswitch_ids        = values(local.primary_interface.vswitch_ids)
  removal_policies   = ["NewestInstance"]
  loadbalancer_ids   = null
  multi_az_policy    = "BALANCE"
  resource_group_id  = var.resource_group_id
  tags               = var.tags

  lifecycle {
    precondition {
      condition     = local.interface_count == 1 || var.function_compute.deploy_function
      error_message = "function_compute.deploy_function must be true when secondary FortiGate interfaces are configured."
    }
  }
}

resource "alicloud_ess_scaling_rule" "scale_out" {
  count             = var.autoscaler.enable_scaling ? 1 : 0
  scaling_group_id  = alicloud_ess_scaling_group.fgt.id
  scaling_rule_name = "${local.resource_prefix}scale-out"
  adjustment_type   = "QuantityChangeInCapacity"
  adjustment_value  = 1
  cooldown          = var.autoscaler.cooldown_period
  depends_on = [
    alicloud_ess_lifecycle_hook.scale_out,
    alicloud_ess_lifecycle_hook.scale_in
  ]
}

resource "alicloud_ess_scaling_rule" "scale_in" {
  count             = var.autoscaler.enable_scaling ? 1 : 0
  scaling_group_id  = alicloud_ess_scaling_group.fgt.id
  scaling_rule_name = "${local.resource_prefix}scale-in"
  adjustment_type   = "QuantityChangeInCapacity"
  adjustment_value  = -1
  cooldown          = var.autoscaler.cooldown_period
  depends_on = [
    alicloud_ess_lifecycle_hook.scale_out,
    alicloud_ess_lifecycle_hook.scale_in
  ]
}

resource "alicloud_ess_alarm" "cpu_high" {
  count               = var.autoscaler.enable_scaling ? 1 : 0
  name                = "${local.resource_prefix}cpu-high"
  description         = "Scale out autoScale group when CPU is high."
  alarm_actions       = [alicloud_ess_scaling_rule.scale_out[0].ari]
  scaling_group_id    = alicloud_ess_scaling_group.fgt.id
  metric_type         = "system"
  metric_name         = "CpuUtilization"
  period              = var.autoscaler.evaluation_period
  statistics          = "Average"
  threshold           = var.autoscaler.cpu_utilization_high
  comparison_operator = ">="
  evaluation_count    = var.autoscaler.evaluation_count
}

resource "alicloud_ess_alarm" "cpu_low" {
  count               = var.autoscaler.enable_scaling ? 1 : 0
  name                = "${local.resource_prefix}cpu-low"
  description         = "Scale in autoScale group when CPU is low."
  alarm_actions       = [alicloud_ess_scaling_rule.scale_in[0].ari]
  scaling_group_id    = alicloud_ess_scaling_group.fgt.id
  metric_type         = "system"
  metric_name         = "CpuUtilization"
  period              = var.autoscaler.evaluation_period
  statistics          = "Average"
  threshold           = var.autoscaler.cpu_utilization_low
  comparison_operator = "<="
  evaluation_count    = var.autoscaler.evaluation_count
}
