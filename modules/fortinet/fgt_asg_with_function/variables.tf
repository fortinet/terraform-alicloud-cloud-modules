# Project Settings
variable "prefix" {
  type        = string
  description = "Prefix of all objects in this module."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.prefix))
    error_message = "prefix must start with a lowercase letter and may only contain lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  type        = string
  description = "Alicloud region."
}


# Network Settings
variable "network" {
  type = object({
    interfaces = map(object({
      vswitch_ids       = map(string)
      security_group_id = string
      route_cidrs       = optional(list(string), [])
    }))
    internet_bandwidth = optional(number, 0)
    ha_sync_interface  = optional(string, "")
  })
  description = <<-EOF
  FortiGate interface definitions and per-zone VSwitch mappings.

  Options:
  - interfaces : (Required | map(object)) FortiGate interfaces keyed consecutively from port1 through portN.
  - interfaces.portN.vswitch_ids : (Required | map(string)) Zone ID to VSwitch ID mappings. Every interface must define the same zones.
  - interfaces.portN.security_group_id : (Required | string) Security group attached to the interface.
  - interfaces.portN.route_cidrs : (Optional | list(string) | default:[]) VPC CIDR routes installed through the interface.
  - internet_bandwidth : (Optional | number | default:0) Public outbound bandwidth in Mbps for port1. Management access uses HTTPS or SSH; HTTP management is disabled.
  - ha_sync_interface : (Optional | string | default:"") FortiGate HA synchronization interface. If empty, the module uses port1 for one interface and port2 for two or more interfaces.

  Example:
  ```
  network = {
    interfaces = {
      port1 = {
        vswitch_ids = {
          "cn-hangzhou-j" = "vsw-inspection-j"
          "cn-hangzhou-k" = "vsw-inspection-k"
        }
        security_group_id = "sg-xxxxxxxx"
        route_cidrs       = ["10.0.0.0/24", "10.0.10.0/24"]
      }
      port2 = {
        vswitch_ids = {
          "cn-hangzhou-j" = "vsw-sync-j"
          "cn-hangzhou-k" = "vsw-sync-k"
        }
        security_group_id = "sg-xxxxxxxx"
        route_cidrs       = ["10.0.1.0/24", "10.0.11.0/24"]
      }
    }
    internet_bandwidth = 10
  }
  ```
  EOF
  validation {
    condition = (
      length(var.network.interfaces) > 0 &&
      toset(keys(var.network.interfaces)) == toset([
        for port_number in range(1, length(var.network.interfaces) + 1) : "port${port_number}"
      ])
    )
    error_message = "network.interfaces keys must be consecutive from port1 through portN."
  }
  validation {
    condition     = try(length(var.network.interfaces["port1"].vswitch_ids) > 0, false)
    error_message = "network.interfaces.port1.vswitch_ids must contain at least one zone mapping."
  }
  validation {
    condition = alltrue(flatten([
      for interface in values(var.network.interfaces) : [
        for zone_id, vswitch_id in interface.vswitch_ids : zone_id != "" && vswitch_id != ""
      ]
    ]))
    error_message = "network.interfaces VSwitch mappings cannot contain empty zone IDs or VSwitch IDs."
  }
  validation {
    condition = try(alltrue([
      for interface in values(var.network.interfaces) :
      toset(keys(interface.vswitch_ids)) == toset(keys(var.network.interfaces["port1"].vswitch_ids))
    ]), false)
    error_message = "Every network interface must define the same zone IDs as port1."
  }
  validation {
    condition = alltrue(flatten([
      for interface in values(var.network.interfaces) : [
        for cidr in interface.route_cidrs : can(cidrnetmask(cidr))
      ]
    ]))
    error_message = "network.interfaces route_cidrs must contain valid IPv4 CIDR blocks."
  }
  validation {
    condition     = var.network.internet_bandwidth >= 0
    error_message = "network.internet_bandwidth must be nonnegative."
  }
  validation {
    condition     = var.network.ha_sync_interface == "" || contains(keys(var.network.interfaces), var.network.ha_sync_interface)
    error_message = "network.ha_sync_interface must reference a configured interface."
  }
}

variable "health_check_port" {
  type        = number
  default     = 8008
  description = "FortiGate probe port for load balancer health checks."
}


# FortiGate Settings
variable "instance_type" {
  type        = string
  default     = ""
  description = "ECS instance type for FortiGate instances. If empty, the module selects an available FortiGate-supported instance type in the current region."
}

variable "fgt_hostname" {
  type        = string
  default     = ""
  description = "FortiGate hostname. Optional, if not provided, it will be <prefix>-fgt by default."
}

variable "fgt_password" {
  type        = string
  sensitive   = true
  nullable    = false
  description = "FortiGate admin password."

  validation {
    condition = (
      length(var.fgt_password) >= 12 &&
      length(var.fgt_password) <= 128 &&
      can(regex("^[!-~]+$", var.fgt_password)) &&
      can(regex("[A-Z]", var.fgt_password)) &&
      can(regex("[a-z]", var.fgt_password)) &&
      can(regex("[0-9]", var.fgt_password)) &&
      can(regex("[[:punct:]]", var.fgt_password))
    )
    error_message = "fgt_password must contain 12 to 128 printable ASCII characters without spaces, including uppercase, lowercase, a digit, and punctuation."
  }
}

variable "image" {
  type = object({
    image_id     = optional(string, "")
    product_type = optional(string, "FortiGate")
    version      = optional(string, "8.0")
    license_type = optional(string, "PAYG")
  })
  default     = {}
  description = <<-EOF
  FortiGate image lookup or explicit image ID.

  Options:
  - image_id : (Optional | string | default:"") Explicit FortiGate image ID, usually in the format "m-xxxxxxxx". If set, image lookup is skipped. Image IDs are region-specific.
  - product_type : (Optional | string | default:"FortiGate") Fortinet marketplace product type used for image lookup.
  - version : (Optional | string | default:"8.0") FortiGate image version used for image lookup.
  - license_type : (Optional | string | default:"PAYG") FortiGate license model used for image lookup.
    - "PAYG": Pay as you go, the license fee is charged by AliCloud.
    - "BYOL": Bring your own license. You need to specify "license.license_source".

  Example: Pay as you go, the license fee is charged by AliCloud.
  ```
  image = {
    product_type = "FortiGate"
    version      = "8.0"
    license_type = "PAYG"
  }
  ```

  Example: Bring your own license.
  ```
  image = {
    product_type = "FortiGate"
    version      = "8.0"
    license_type = "BYOL"
  }
  ```

  Example: Explicit image ID.
  ```
  image = {
    image_id = "m-xxxxxxxx"
  }
  ```
  EOF
}

variable "system_disk" {
  type = object({
    name              = optional(string, "")
    description       = optional(string, null)
    size              = optional(number, 40)
    category          = optional(string, "cloud_essd")
    performance_level = optional(string, "PL1")
  })
  default     = {}
  description = <<-EOF
  FortiGate system disk configuration.

  Options:
  - name : (Optional | string | default:"") System disk name. If empty, the module generates one.
  - description : (Optional | string | default:null) System disk description.
  - size : (Optional | number | default:40) System disk size in GB.
  - category : (Optional | string | default:"cloud_essd") System disk category.
  - performance_level : (Optional | string | default:"PL1") ESSD performance level.

  Example:
  ```
  system_disk = {
    size              = 40
    category          = "cloud_essd"
    performance_level = "PL1"
  }
  ```
  EOF
}

variable "data_disks" {
  type = list(object({
    name              = optional(string, "")
    description       = optional(string, null)
    size              = number
    category          = optional(string, "cloud_essd")
    performance_level = optional(string, "PL1")
  }))
  default     = []
  description = <<-EOF
  Additional FortiGate data disks.

  Options:
  - name : (Optional | string | default:"") Data disk name. If empty, the module generates one.
  - description : (Optional | string | default:null) Data disk description.
  - size : (Required | number) Data disk size in GB.
  - category : (Optional | string | default:"cloud_essd") Data disk category.
  - performance_level : (Optional | string | default:"PL1") ESSD performance level.

  Example:
  ```
  data_disks = [
    {
      size              = 40
      category          = "cloud_essd"
      performance_level = "PL1"
    }
  ]
  ```
  EOF
}


# License
variable "license" {
  type = object({
    license_source      = optional(string, "none")
    license_file_folder = optional(string, "./licenses")
    fortiflex = optional(object({
      retrieve_mode = optional(string, "use_stopped")
      username      = optional(string, "")
      password      = optional(string, "")
      config        = optional(string, "")
      }), {}
    )
  })
  default     = {}
  description = <<-EOF
  FortiGate license settings used by Function Compute.

  If function_compute.deploy_function is false, license handling is disabled and this variable has no effect.

  Options:
  - license_source : (Optional | string | default:"none") FortiGate license source. Use "none" for PAYG, "file" for local license files, "fortiflex" for FortiFlex, or "file_fortiflex" to try local files first and fall back to FortiFlex.
  - license_file_folder : (Optional | string | default:"./licenses") Local folder that stores FortiGate license files when license_source uses file licenses.
  - fortiflex : (Optional | object | default:{}) FortiFlex settings used when license_source is "fortiflex" or "file_fortiflex".
  - fortiflex.retrieve_mode : (Optional | string | default:"use_stopped") FortiFlex entitlement retrieval mode. Valid values:
    - "use_stopped": Activates an EXPIRED, STOPPED, or PENDING entitlement and refreshes its token.
    - "use_active": Selects an ACTIVE or PENDING entitlement with an unused token.
  - fortiflex.username : (Optional | string | default:"") FortiFlex username.
  - fortiflex.password : (Optional | string | default:"") FortiFlex password.
  - fortiflex.config : (Optional | string | default:"") FortiFlex configuration ID.

  Example: No license injection. "image.license_type" should be PAYG.
  ```
  license = {
    license_source      = "none"
  }
  ```

  Example: License file injection. "image.license_type" should be BYOL.
  ```
  license = {
    license_source      = "file"
    license_file_folder = "/path/to/license_file_folder/"
  }
  ```

  Example: FortiFlex activation. "image.license_type" should be BYOL.
  ```
  license = {
    license_source = "fortiflex"
    fortiflex = {
      username      = "XXXXX" # The username of your FortiFlex account.
      password      = "YYYYY" # The password of your FortiFlex account.
      config        = "1234"  # The FortiFlex configuration ID.
      retrieve_mode = "use_stopped"
    }
  }
  ```

  Example: License file activation with FortiFlex fallback. "image.license_type" should be BYOL.
  ```
  license = {
    license_source      = "file_fortiflex"
    license_file_folder = "/path/to/license_file_folder/"
    fortiflex = {
      username      = "XXXXX" # The username of your FortiFlex account.
      password      = "YYYYY" # The password of your FortiFlex account.
      config        = "1234"  # The FortiFlex configuration ID.
      retrieve_mode = "use_stopped"
    }
  }
  ```
  EOF
  validation {
    condition     = contains(["none", "file", "fortiflex", "file_fortiflex"], var.license.license_source)
    error_message = "license.license_source must be one of: none, file, fortiflex, file_fortiflex."
  }
}


# Function Compute
variable "function_compute" {
  type = object({
    deploy_function        = optional(bool, true)
    autoscale_psksecret    = string
    ots_instance_name      = optional(string, "")
    ots_table_name         = optional(string, "")
    use_existing_ots_table = optional(bool, false)
    logging_level          = optional(string, "INFO")
    vpc_id                 = optional(string, "")
    vswitch_ids            = optional(list(string), [])
    security_group_id      = optional(string, "")
    additional_variables   = optional(map(string), {})
  })
  description = <<-EOF
  Function Compute settings for FortiGate autoscale lifecycle handling.

  Options:
  - deploy_function : (Optional | bool | default:true) Whether to deploy Function Compute resources. Set it to false only when FortiManager manages the FortiGate Auto Scaling group. Otherwise, disabling Function Compute prevents the module from operating correctly.
  - autoscale_psksecret : (Required | string) FortiGate autoscale pre-shared key. The value must not be empty.
  - ots_instance_name : (Optional | string | default:"") Existing OTS instance name. If empty, the module creates one. Required when ots_table_name is set.
  - ots_table_name : (Optional | string | default:"") Existing OTS table to reuse without creating or managing the instance or table. If empty, the module creates a table with a generated name. The existing table must have one String primary key named ID.
  - logging_level : (Optional | string | default:"INFO") Function logging level. Valid values are "ERROR", "WARN", "INFO", "DEBUG", "TRACE", and "NONE".
  - vpc_id : (Optional | string | default:"") VPC ID used by Function Compute.
  - vswitch_ids : (Optional | list(string) | default:[]) VSwitch IDs used by Function Compute.
  - security_group_id : (Optional | string | default:"") Security group ID used by Function Compute.
  - additional_variables : (Optional | map(string) | default:{}) Additional environment variables passed to the function. Module-managed variables take precedence when keys overlap.

  Example:
  ```
  function_compute = {
    deploy_function     = true
    autoscale_psksecret = "YOUR_SHARED_AUTOSCALE_PSK"
    logging_level       = "INFO"
    vpc_id              = "vpc-xxxxxxxx"
    vswitch_ids         = ["vsw-xxxxxxxx"]
    security_group_id   = "sg-xxxxxxxx"
    additional_variables = {}
    # To reuse an existing state table, set both values.
    # ots_instance_name = "shared-ots"
    # ots_table_name    = "shared_fgt_state"
  }
  ```
  EOF
  validation {
    condition     = try(length(trimspace(var.function_compute.autoscale_psksecret)) > 0, false)
    error_message = "function_compute.autoscale_psksecret must be supplied and must not be empty."
  }
  validation {
    condition     = var.function_compute.ots_table_name == "" || var.function_compute.ots_instance_name != ""
    error_message = "function_compute.ots_instance_name is required when function_compute.ots_table_name is set."
  }
  validation {
    condition     = !var.function_compute.use_existing_ots_table || var.function_compute.ots_table_name != ""
    error_message = "function_compute.ots_table_name is required when function_compute.use_existing_ots_table is true."
  }
  validation {
    condition     = contains(["ERROR", "WARN", "INFO", "DEBUG", "TRACE", "NONE"], upper(var.function_compute.logging_level))
    error_message = "logging_level must be one of: ERROR, WARN, INFO, DEBUG, TRACE, NONE."
  }
  validation {
    condition     = !var.function_compute.deploy_function || (var.function_compute.vpc_id != "" && length(var.function_compute.vswitch_ids) > 0 && var.function_compute.security_group_id != "")
    error_message = "function_compute.vpc_id, function_compute.vswitch_ids, and function_compute.security_group_id are required for Function Compute VPC configuration."
  }
}

variable "autoscaler" {
  type = object({
    enable_scaling       = optional(bool, true)
    max_instances        = number
    min_instances        = optional(number, 1)
    desired_capacity     = optional(number, null)
    cooldown_period      = optional(number, 300)
    cpu_utilization_high = optional(number, 80)
    cpu_utilization_low  = optional(number, 20)
    evaluation_count     = optional(number, 3)
    evaluation_period    = optional(number, 60)
  })
  description = <<-EOF
  ESS autoscaling settings for the FortiGate autoscale group.

  Options:
  - enable_scaling : (Optional | bool | default:true) Whether to create this group's native CPU alarms and scaling rules. Disabling them preserves the ASG capacity settings and lifecycle hooks. Use false for fixed capacity or external scaling control.
  - max_instances : (Required | number) Maximum number of FortiGate instances.
  - min_instances : (Optional | number | default:1) Minimum number of FortiGate instances.
  - desired_capacity : (Optional | number | default:null) Desired FortiGate instance count. Initial scaling starts after lifecycle hooks are ready when Function Compute is enabled. If null, ESS uses its default behavior.
  - cooldown_period : (Optional | number | default:300) Cooldown period in seconds between scaling activities.
  - cpu_utilization_high : (Optional | number | default:80) Average CPU utilization threshold that triggers scale out.
  - cpu_utilization_low : (Optional | number | default:20) Average CPU utilization threshold that triggers scale in.
  - evaluation_count : (Optional | number | default:3) Number of evaluation periods required before a scaling alarm changes state.
  - evaluation_period : (Optional | number | default:60) Metric evaluation period in seconds.

  Example:
  ```
  autoscaler = {
    min_instances        = 1
    max_instances        = 4
    desired_capacity     = 1
    cooldown_period      = 300
  }
  ```
  EOF
}


# FortiGate Configuration
variable "config_script" {
  type        = string
  default     = ""
  description = "Additional FortiGate configuration script."
}

variable "config_file" {
  type        = string
  default     = ""
  description = "Additional FortiGate configuration file."
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
