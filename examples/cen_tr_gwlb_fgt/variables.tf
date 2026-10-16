# Project Settings
variable "prefix" {
  type    = string
  default = "cen-tr-gwlb"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.prefix))
    error_message = "prefix must start with a lowercase letter and may only contain lowercase letters, numbers, and hyphens."
  }
  description = "Prefix of all resources in this example."
}

variable "access_key" {
  type        = string
  default     = ""
  description = "Alibaba Cloud access key ID. Alternatively, leave this empty and set the ALIBABA_CLOUD_ACCESS_KEY_ID environment variable."
}

variable "secret_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Alibaba Cloud access key secret. Alternatively, leave this empty and set the ALIBABA_CLOUD_ACCESS_KEY_SECRET environment variable."
}

variable "region" {
  type        = string
  description = "Alicloud region."
}

variable "cen_id" {
  type        = string
  default     = ""
  description = <<-EOF
  ID of an existing Cloud Enterprise Network (CEN) instance in which to create the Transit Router
  that connects the business VPCs to the Security VPC.

  If unset or empty, the example creates a new CEN instance.
  EOF
}


# Network Settings
variable "security_vpc" {
  type = object({
    cidr = string
    zones = map(object({
      inspection_vswitch_cidr = string
      tr_vswitch_cidr         = string
      gwlbe_vswitch_cidr      = string
      nat_vswitch_cidr        = string
      sync_vswitch_cidr       = optional(string, "")
    }))
  })

  validation {
    condition     = length(var.security_vpc.zones) > 0
    error_message = "security_vpc.zones must contain at least one zone."
  }
  description = <<-EOF
  Security VPC CIDR block and per-zone VSwitch CIDR blocks. Ensure that these CIDR blocks do not overlap with business VPC CIDR blocks.

  Options:
  - cidr : (Required | string) CIDR block of the Security VPC.
  - zones : (Required | map(object)) Security VPC network settings keyed by zone ID. Use one entry for a single-zone deployment or multiple entries for a multi-zone deployment. At least one zone is required.
  - zones.inspection_vswitch_cidr : (Required | string) CIDR block of the VSwitch used by FortiGate port1 and GWLB in this zone.
  - zones.tr_vswitch_cidr : (Required | string) CIDR block of the CEN Transit Router attachment VSwitch in this zone.
  - zones.gwlbe_vswitch_cidr : (Required | string) CIDR block of the Gateway Load Balancer endpoint VSwitch in this zone.
  - zones.nat_vswitch_cidr : (Required | string) CIDR block of the VSwitch used by the CrossAZ NAT Gateway anchored in this zone.
  - zones.sync_vswitch_cidr : (Required when fgt_network_mode is "dual-port" | string) CIDR block of the VSwitch used by FortiGate port2. Ignored in single-port mode.

  Example:
  ```
  security_vpc = {
    cidr = "192.168.0.0/16"
    zones = {
      ap-northeast-1a = {
        inspection_vswitch_cidr = "192.168.0.0/24"
        tr_vswitch_cidr         = "192.168.1.0/24"
        gwlbe_vswitch_cidr      = "192.168.2.0/24"
        nat_vswitch_cidr        = "192.168.3.0/24"
        # sync_vswitch_cidr     = "192.168.4.0/24" # Required when fgt_network_mode is "dual-port".
      }
      # Uncomment this block to deploy the Security VPC across multiple zones.
      # ap-northeast-1c = {
      #   inspection_vswitch_cidr = "192.168.10.0/24"
      #   tr_vswitch_cidr         = "192.168.11.0/24"
      #   gwlbe_vswitch_cidr      = "192.168.12.0/24"
      #   nat_vswitch_cidr        = "192.168.13.0/24"
      #   sync_vswitch_cidr       = "192.168.14.0/24" # Required when fgt_network_mode is "dual-port".
      # }
    }
  }
  ```
  EOF
}

variable "business_vpcs" {
  type = map(object({
    cidr                 = string
    vpc_id               = string
    workload_vswitch_ids = set(string)
    tr_vswitches = map(object({
      vswitch_id = optional(string, "")
      cidr       = optional(string, "")
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for business_key in keys(var.business_vpcs) : can(regex("^[a-z][a-z0-9-]*$", business_key))])
    error_message = "business_vpcs keys must start with a lowercase letter and may only contain lowercase letters, numbers, and hyphens."
  }
  validation {
    condition     = !contains(keys(var.business_vpcs), "security")
    error_message = "The business_vpcs key \"security\" is reserved for the Security VPC. Choose another name."
  }
  validation {
    condition = alltrue([
      for business_vpc in var.business_vpcs : alltrue([
        for tr_vswitch in values(business_vpc.tr_vswitches) : (tr_vswitch.vswitch_id != "") != (tr_vswitch.cidr != "")
      ])
    ])
    error_message = "Each business VPC Transit Router zone must set exactly one of vswitch_id or cidr."
  }
  validation {
    condition     = alltrue([for business_vpc in var.business_vpcs : length(business_vpc.workload_vswitch_ids) > 0])
    error_message = "Each business VPC must provide at least one workload VSwitch ID."
  }

  description = <<-EOF
  Existing business VPCs to connect to the CEN Transit Router.

  Map keys must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens. The name "security" is reserved for the Security VPC.

  Options:
  - cidr : (Required | string) CIDR block of the business VPC.
  - vpc_id : (Required | string) ID of the existing business VPC.
  - workload_vswitch_ids : (Required | set(string)) IDs of business workload VSwitches whose default route is sent to the Transit Router.
  - tr_vswitches : (Required | map(object)) Transit Router attachment VSwitch settings keyed by zone ID. Each business VPC can use one or more Transit Router supported zones independently of security_vpc.zones, subject to Alibaba Cloud attachment requirements.
  - tr_vswitches.vswitch_id : (Optional | string | default:"") ID of an existing Transit Router attachment VSwitch in this zone.
  - tr_vswitches.cidr : (Optional | string | default:"") CIDR block used to create a Transit Router attachment VSwitch in this zone.

  Each Transit Router zone must set exactly one of vswitch_id or cidr.

  Example:
  ```
  business_vpcs = {
    business-a = {
      cidr                  = "10.10.0.0/16"
      vpc_id                = "vpc-xxxxxxxx"
      workload_vswitch_ids = ["vsw-workload-a", "vsw-workload-c"]
      tr_vswitches = {
        # Configure one VSwitch per zone for this business VPC's Transit Router attachment.
        # Set either cidr to create a VSwitch or vswitch_id to reuse one.
        ap-northeast-1a = {
          cidr = "10.10.2.0/24" # Create a TR attachment VSwitch in this business VPC and zone.
        }
        ap-northeast-1c = {
          vswitch_id = "vsw-tr-c" # Reuse a TR attachment VSwitch in this business VPC and zone.
        }
      }
    }
    # business-b = {
    #   cidr                  = "10.20.0.0/16"
    #   vpc_id                = "vpc-yyyyyyyy"
    #   workload_vswitch_ids = ["vsw-workload-b"]
    #   tr_vswitches = {
    #     ap-northeast-1a = { cidr = "10.20.2.0/24" }
    #   }
    # }
  }
  ```
  EOF
}

variable "outbound_bandwidth" {
  type        = number
  default     = 10
  nullable    = false
  description = "Maximum outbound bandwidth in Mbps for each NAT EIP. Defaults to 10."

  validation {
    condition     = var.outbound_bandwidth > 0 && floor(var.outbound_bandwidth) == var.outbound_bandwidth
    error_message = "outbound_bandwidth must be a positive integer."
  }
}

variable "security_attachment_appliance_mode_support" {
  type        = string
  default     = "enable"
  nullable    = true
  description = "Appliance mode setting for the Security VPC Transit Router attachment, used for traffic redirection to security appliances. Set to null to omit this option."
}

# FortiGate Groups
variable "fortigate_asgs" {
  type = map(object({
    instance_type     = optional(string, "")
    fgt_hostname      = optional(string, "")
    fgt_has_public_ip = optional(bool, false)
    image = optional(object({
      image_id     = optional(string, "")
      product_type = optional(string, "FortiGate")
      version      = optional(string, "8.0")
      license_type = optional(string, "PAYG")
    }), {})
    system_disk = optional(object({
      name              = optional(string, "")
      description       = optional(string, null)
      size              = optional(number, 40)
      category          = optional(string, "cloud_essd")
      performance_level = optional(string, "PL1")
    }), {})
    data_disks = optional(list(object({
      name              = optional(string, "")
      description       = optional(string, null)
      size              = number
      category          = optional(string, "cloud_essd")
      performance_level = optional(string, "PL1")
    })), [])
    license = optional(object({
      license_source      = optional(string, "none")
      license_file_folder = optional(string, "./licenses")
      fortiflex = optional(object({
        retrieve_mode = optional(string, "use_stopped")
        username      = optional(string, "")
        password      = optional(string, "")
        config        = optional(string, "")
        }), {}
      )
    }), {})
    autoscaler = object({
      enable_scaling       = optional(bool, true)
      max_instances        = number
      min_instances        = optional(number, 2)
      desired_capacity     = optional(number, null)
      cooldown_period      = optional(number, 300)
      cpu_utilization_high = optional(number, 80)
      cpu_utilization_low  = optional(number, 20)
      evaluation_count     = optional(number, 3)
      evaluation_period    = optional(number, 60)
    })
    function_compute = optional(object({
      deploy_function      = optional(bool, true)
      logging_level        = optional(string, "INFO")
      additional_variables = optional(map(string), {})
    }), {})
  }))
  sensitive = true
  nullable  = false

  description = <<-EOF
  FortiGate Auto Scaling groups keyed by a stable group name, such as byol or payg. At least one group is required. Each group creates its own ASG. Groups with function_compute.deploy_function enabled also create a lifecycle Function, messaging resources, OSS bucket, and execution roles, and share the example-managed Tablestore table. All groups share the management password, autoscale pre-shared key, network, GWLB, health checks, interface mode, and extra FortiGate configuration.

  Group options:
  - instance_type : (Optional | string | default:"") ECS instance type. If empty, the module selects an available FortiGate-supported type.
  - fgt_hostname : (Optional | string | default:"") FortiGate hostname. If empty, the module derives one from the deployment prefix and group name.
  - fgt_has_public_ip : (Optional | bool | default:false) Whether port1 receives a public IP with 10 Mbps outbound bandwidth for HTTPS or SSH management. Keep false and manage FortiGate over the private network, as recommended. Set true only for debugging.
  - image : (Optional | object | default:{}) Image settings: image_id, product_type (FortiGate), version (8.0), and license_type (PAYG). An explicit image_id skips marketplace lookup; still declare the correct license_type.
  - system_disk : (Optional | object | default:{}) System disk settings: name (empty), description (null), size (40 GB), category (cloud_essd), and performance_level (PL1).
  - data_disks : (Optional | list(object) | default:[]) Additional disk settings. Each disk requires size; other fields have the same defaults as system_disk.
  - license : (Optional | object | default:{}) License settings: license_source (none), license_file_folder (./licenses), and fortiflex. PAYG uses none. BYOL uses file, fortiflex, or file_fortiflex when Function Compute is enabled.
  - license.fortiflex : (Optional | object | default:{}) FortiFlex settings: username, password, config (all empty), and retrieve_mode (use_stopped or use_active; default: use_stopped).
  - autoscaler : (Required | object) Group capacity and native CPU scaling settings. Both BYOL and PAYG support fixed capacity or autoscaling. max_instances is required. min_instances defaults to 2; desired_capacity defaults to null. enable_scaling defaults to true and controls native CPU alarms and scaling rules only. Set enable_scaling=false and min_instances=max_instances=desired_capacity=N for a fixed group. Set enable_scaling=false when an external controller manages capacity.
  - autoscaler.cooldown_period : (Optional | number | default:300) Scaling cooldown in seconds.
  - autoscaler.cpu_utilization_high / cpu_utilization_low : (Optional | number | default:80 / 20) CPU thresholds for this group's instances. These are not fleet-wide metrics.
  - autoscaler.evaluation_count / evaluation_period : (Optional | number | default:3 / 60) Evaluation count and period in seconds.
  - function_compute : (Optional | object | default:{}) Per-group Function settings: deploy_function (true), logging_level (INFO), and additional_variables ({}). Omit to use these defaults. Disable deploy_function only when an external system manages this group in single-port mode. The shared state table is created when any group enables Function Compute. Module-managed environment variables take precedence over additional_variables.

  Use terraform.tfvars.one_asg.template for one group or terraform.tfvars.two_asg.template for two independently configured groups. Native CPU alarms cannot start an empty group from zero, regardless of license type. Traffic-based startup and fleet-wide CPU scaling require a separate controller.

  Example: One PAYG group with native CPU scaling.
  ```
  fortigate_asgs = {
    payg = {
      image = {
        license_type = "PAYG"
        version      = "8.0"
      }
      system_disk = { size = 40, category = "cloud_essd", performance_level = "PL1" }
      data_disks  = [{ size = 100, category = "cloud_essd", performance_level = "PL1" }]
      license = { license_source = "none" }
      autoscaler = {
        enable_scaling   = true
        min_instances    = 2
        max_instances    = 4
        desired_capacity = 2
      }
      function_compute = {
        logging_level = "INFO"
      }
    }
  }
  ```

  Example: Two groups, one with fixed capacity and one with native CPU scaling.
  ```
  fortigate_asgs = {
    byol = {
      image = {
        license_type = "BYOL"
        version      = "8.0"
      }
      system_disk = { size = 40, category = "cloud_essd", performance_level = "PL1" }
      data_disks  = [{ size = 100, category = "cloud_essd", performance_level = "PL1" }]
      license = {
        license_source      = "file"
        license_file_folder = "/path/to/byol/licenses"
      }
      autoscaler = {
        enable_scaling   = false
        min_instances    = 2
        max_instances    = 2
        desired_capacity = 2
      }
      function_compute = {
        logging_level = "INFO"
      }
    }
    payg = {
      image       = { license_type = "PAYG", version = "8.0" }
      system_disk = { size = 40, category = "cloud_essd", performance_level = "PL1" }
      data_disks  = [{ size = 100, category = "cloud_essd", performance_level = "PL1" }]
      license     = { license_source = "none" }
      autoscaler = {
        enable_scaling   = true
        min_instances    = 1
        max_instances    = 4
        # desired_capacity = 1
      }
      function_compute = {
        logging_level = "INFO"
      }
    }
  }
  ```
  The PAYG group keeps at least one instance so native CPU scaling can operate. Leave desired_capacity unset to use ESS default behavior.
  EOF

  validation {
    condition     = length(var.fortigate_asgs) > 0 && alltrue([for name in keys(var.fortigate_asgs) : can(regex("^[a-z][a-z0-9-]*$", name))])
    error_message = "fortigate_asgs must contain at least one group. Group names must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
  }
  validation {
    condition = alltrue([for group in values(var.fortigate_asgs) : (
      group.autoscaler.min_instances >= 0 && floor(group.autoscaler.min_instances) == group.autoscaler.min_instances &&
      group.autoscaler.max_instances >= group.autoscaler.min_instances && floor(group.autoscaler.max_instances) == group.autoscaler.max_instances &&
      (group.autoscaler.desired_capacity == null ? true : (
        group.autoscaler.desired_capacity >= group.autoscaler.min_instances &&
        group.autoscaler.desired_capacity <= group.autoscaler.max_instances &&
        floor(group.autoscaler.desired_capacity) == group.autoscaler.desired_capacity
      ))
    )])
    error_message = "Every group's capacity values must be non-negative integers, min_instances must not exceed max_instances, and desired_capacity must be null or within those bounds."
  }
  validation {
    condition     = alltrue([for group in values(var.fortigate_asgs) : contains(["PAYG", "BYOL"], group.image.license_type) && contains(["none", "file", "fortiflex", "file_fortiflex"], group.license.license_source)])
    error_message = "Each group must use image.license_type PAYG or BYOL and license.license_source none, file, fortiflex, or file_fortiflex."
  }
  validation {
    condition     = alltrue([for group in values(var.fortigate_asgs) : contains(["ERROR", "WARN", "INFO", "DEBUG", "TRACE", "NONE"], upper(group.function_compute.logging_level))])
    error_message = "Each group's logging_level must be ERROR, WARN, INFO, DEBUG, TRACE, or NONE."
  }
}

# Shared FortiGate Settings


variable "fgt_password" {
  type        = string
  default     = ""
  sensitive   = true
  nullable    = false
  description = "FortiGate admin password. If empty, the example generates one."
}


variable "fgt_network_mode" {
  type        = string
  default     = "single-port"
  description = <<-EOF
  FortiGate network interface mode:
  - single-port: port1 handles management, GWLB inspection, and HA synchronization.
  - dual-port: port1 handles management and GWLB inspection; port2 handles HA synchronization.

  Dual-port requires sync_vswitch_cidr in each security VPC zone and function_compute.deploy_function = true in every group to create and attach port2.
  EOF

  validation {
    condition     = contains(["single-port", "dual-port"], var.fgt_network_mode)
    error_message = "fgt_network_mode must be either single-port or dual-port."
  }
}


# Health Check
variable "health_check" {
  type = object({
    health_check_enabled         = optional(bool, true)
    health_check_protocol        = optional(string, "TCP")
    health_check_connect_port    = optional(number, 8008)
    health_check_connect_timeout = optional(number, 5)
    health_check_interval        = optional(number, 10)
    healthy_threshold            = optional(number, 3)
    unhealthy_threshold          = optional(number, 3)
    connection_drain_enabled     = optional(bool, false)
    connection_drain_timeout     = optional(number, 300)
  })
  default = {}

  description = <<-EOF
  GWLB health check and connection drain settings. The default values are suitable for most deployments.

  Options:
  - health_check_enabled : (Optional | bool | default:true) Whether to enable GWLB server group health checks.
  - health_check_protocol : (Optional | string | default:"TCP") Health check protocol.
  - health_check_connect_port : (Optional | number | default:8008) Health check port used by GWLB and FortiGate.
  - health_check_connect_timeout : (Optional | number | default:5) Health check timeout in seconds.
  - health_check_interval : (Optional | number | default:10) Health check interval in seconds.
  - healthy_threshold : (Optional | number | default:3) Number of successful checks required before a FortiGate is considered healthy.
  - unhealthy_threshold : (Optional | number | default:3) Number of failed checks required before a FortiGate is considered unhealthy.
  - connection_drain_enabled : (Optional | bool | default:false) Whether to enable connection draining.
  - connection_drain_timeout : (Optional | number | default:300) Connection drain timeout in seconds.

  Example:
  ```
  # The default values are suitable for most deployments.
  health_check = {}
  ```
  EOF
}


variable "autoscale_psksecret" {
  type        = string
  default     = ""
  sensitive   = true
  nullable    = false
  description = "Shared FortiGate autoscale pre-shared key passed to every ASG module. If empty, the example generates one."
}

variable "ots_instance_name" {
  type        = string
  default     = ""
  nullable    = false
  description = "Existing OTS instance in which the example creates its shared state table. If empty, the example creates an instance. The example manages the table name internally."
}


# FortiGate Configuration
variable "config_file" {
  type        = string
  default     = ""
  description = "Path to a FortiGate CLI configuration file."
}

variable "config_script" {
  type        = string
  default     = <<-EOF
  config firewall policy
      edit 1000
          set name "gwlb-traffic-inspection"
          set srcintf "gwlb-inspection"
          set dstintf "gwlb-inspection"
          set srcaddr "all"
          set dstaddr "all"
          set action accept
          set schedule "always"
          set service "ALL"
          set logtraffic all
      next
  end
  EOF
  description = "Additional FortiGate configuration script."
}

# Resource Identification
variable "resource_group_id" {
  type        = string
  default     = null
  description = "Alibaba Cloud resource group ID assigned to resources."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to supported resources."
}
