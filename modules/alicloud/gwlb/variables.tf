variable "prefix" {
  type        = string
  description = "Prefix of all resources in this module. Resource names are inferred from this prefix."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the GWLB load balancer and server group are deployed."
}

variable "zone_mappings" {
  type = list(object({
    zone_id    = string
    vswitch_id = string
  }))
  description = <<-EOF
    GWLB zone and VSwitch mappings.
    Options:
      - zone_id : (Required | string) Zone ID where the GWLB is deployed.
      - vswitch_id : (Required | string) VSwitch ID used by the GWLB in this zone.
    Example:
    ```
    zone_mappings = [
      {
        zone_id    = "cn-guangzhou-a"
        vswitch_id = "vsw-xxxxxxxx"
      }
    ]
    ```
  EOF
  validation {
    condition     = length(var.zone_mappings) > 0
    error_message = "At least one zone mapping is required."
  }
  validation {
    condition     = length(distinct([for mapping in var.zone_mappings : mapping.zone_id])) == length(var.zone_mappings)
    error_message = "Each zone ID may appear only once in zone_mappings."
  }
}

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
  default     = {}
  description = <<-EOF
    GWLB server group health check and connection drain configuration.
    Options:
      - health_check_enabled : (Optional | bool | default:true) Whether to enable health checks.
      - health_check_protocol : (Optional | string | default:"TCP") Health check protocol.
      - health_check_connect_port : (Optional | number | default:8008) Health check port.
      - health_check_connect_timeout : (Optional | number | default:5) Health check timeout in seconds.
      - health_check_interval : (Optional | number | default:10) Health check interval in seconds.
      - healthy_threshold : (Optional | number | default:3) Number of successful checks required before a server is considered healthy.
      - unhealthy_threshold : (Optional | number | default:3) Number of failed checks required before a server is considered unhealthy.
      - connection_drain_enabled : (Optional | bool | default:false) Whether to enable connection draining.
      - connection_drain_timeout : (Optional | number | default:300) Connection drain timeout in seconds.
    Example:
    ```
    health_check = {
      health_check_enabled         = true
      health_check_protocol        = "TCP"
      health_check_connect_port    = 8008
      health_check_connect_timeout = 5
      health_check_interval        = 10
      healthy_threshold            = 3
      unhealthy_threshold          = 3
      connection_drain_enabled     = false
      connection_drain_timeout     = 300
    }
    ```
  EOF
}

variable "resource_group_id" {
  type        = string
  default     = null
  description = "Resource group ID."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to supported resources."
}
