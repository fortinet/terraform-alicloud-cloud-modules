variable "prefix" {
  type        = string
  description = "Prefix of all resources in this module. Resource names are inferred from this prefix."
}

variable "vpc_id" {
  type        = string
  description = "Consumer VPC ID where the GWLBe is created."
}

variable "service_id" {
  type        = string
  default     = ""
  description = "PrivateLink endpoint service ID. Either service_id or service_name must be set."
}

variable "service_name" {
  type        = string
  default     = ""
  description = "PrivateLink endpoint service name. Either service_id or service_name must be set."
}

variable "endpoint_zones" {
  type = map(object({
    vswitch_id = string
  }))
  description = <<-EOF
    GWLBe VSwitch mappings keyed by zone ID. The actual zone is inferred from the VSwitch, which must belong to the corresponding zone. Each key creates one single-zone endpoint. Adding or removing another zone does not change existing endpoint resource addresses.
    Options:
      - vswitch_id : (Required | string) Consumer-side VSwitch ID for the endpoint zone.
    Example:
    ```
    endpoint_zones = {
      cn-guangzhou-a = {
        vswitch_id = "vsw-xxxxxxxx"
      }
    }
    ```
  EOF
  validation {
    condition     = length(var.endpoint_zones) > 0
    error_message = "At least one endpoint zone is required."
  }
  validation {
    condition     = alltrue([for zone_id in keys(var.endpoint_zones) : can(regex("^[a-z][a-z0-9-]*$", zone_id))])
    error_message = "endpoint_zones keys must be zone IDs containing lowercase letters, numbers, and hyphens."
  }
}

variable "route_entries" {
  type = map(object({
    route_table_id        = string
    destination_cidrblock = string
    endpoint_zone_key     = string
    name                  = optional(string, "")
    description           = optional(string, "")
  }))
  default     = {}
  description = <<-EOF
    Route entries keyed by a stable name, such as zone ID and purpose, that send consumer VPC traffic to the GWLBe.
    Leave this map empty when route tables are managed outside this module or when only the endpoint should be created.
    Options:
      - route_table_id : (Required | string) Route table ID where the route entry is created.
      - destination_cidrblock : (Required | string) Destination CIDR block routed to the GWLBe.
      - endpoint_zone_key : (Required | string) Zone ID key in endpoint_zones used as the route next hop. Use the endpoint in the same zone as the VSwitch associated with the route table.
      - name : (Optional | string | default:"") Route entry name.
      - description : (Optional | string | default:"") Route entry description.
    Example:
    ```
    route_entries = {
      "cn-guangzhou-a/default" = {
        route_table_id        = "vtb-xxxxxxxx"
        destination_cidrblock = "0.0.0.0/0"
        endpoint_zone_key     = "cn-guangzhou-a"
        name                  = "default-to-gwlbe"
        description           = "Send traffic to the GWLBe."
      }
    }
    ```
  EOF

  validation {
    condition = alltrue([
      for route in var.route_entries : contains(keys(var.endpoint_zones), route.endpoint_zone_key)
    ])
    error_message = "Every route_entries endpoint_zone_key must identify an endpoint_zones zone ID key."
  }
  validation {
    condition     = alltrue([for key in keys(var.route_entries) : trimspace(key) != ""])
    error_message = "Route entry keys must not be empty."
  }
}

# Optional
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
