variable "prefix" {
  type        = string
  description = "Prefix of all resources in this module. Resource names are inferred from this prefix unless specified by the user."
}

variable "cen_id" {
  type        = string
  description = "CEN instance ID where the Transit Router is created."
}

variable "name" {
  type        = string
  default     = ""
  description = "Transit Router name. If empty, the module uses '<prefix>-tr'."
}

variable "description" {
  type        = string
  default     = ""
  description = "Transit Router description."
}

variable "support_multicast" {
  type        = bool
  default     = false
  description = "Whether to enable multicast for the Enterprise Edition Transit Router."
}

variable "route_tables" {
  type = map(object({
    name        = optional(string, "")
    description = optional(string, "")
  }))
  default     = {}
  description = <<-EOF
    Transit Router route tables to create.
    Options:
      - name : (Optional | string | default:"") Route table name. If empty, the module uses '<prefix>-<map key>'.
      - description : (Optional | string | default:"") Route table description.
    Example:
    ```
    route_tables = {
      spoke = {}
      inspection = {
        description = "Routes for inspected traffic"
      }
    }
    ```
  EOF
}

variable "vpc_attachments" {
  type = map(object({
    vpc_id                     = string
    zone_mappings              = list(object({ zone_id = string, vswitch_id = string }))
    name                       = optional(string, "")
    description                = optional(string, "")
    auto_publish_route_enabled = optional(bool, false)
    force_delete               = optional(bool, false)
    order_type                 = optional(string)
    payment_type               = optional(string)
    options = optional(object({
      appliance_mode_support = optional(string)
      ipv6_support           = optional(string)
    }))
  }))
  default     = {}
  description = <<-EOF
    VPC attachments to create on the Transit Router.
    Options:
      - vpc_id : (Required | string) VPC ID to attach.
      - zone_mappings : (Required | list(object)) Zone and VSwitch mappings for the VPC attachment. Up to 10 mappings are supported by the API.
        - zone_id : (Required | string) Zone ID supported by the Enterprise Edition Transit Router.
        - vswitch_id : (Required | string) VSwitch ID used by this VPC attachment in the zone.
      - name : (Optional | string | default:"") VPC attachment name. If empty, the module uses '<prefix>-<map key>'.
      - description : (Optional | string | default:"") VPC attachment description.
      - auto_publish_route_enabled : (Optional | bool | default:false) Whether the Transit Router automatically advertises routes to the VPC.
      - force_delete : (Optional | bool | default:false) Whether to forcibly delete related association and propagation dependencies when deleting the attachment.
      - order_type : (Optional | string) Payer of the attachment fees. Valid values: PayByCenOwner, PayByResourceOwner.
      - payment_type : (Optional | string) Billing method. Leave null to use the provider default.
      - options : (Optional | object) Feature options for the VPC attachment.
        - appliance_mode_support : (Optional | string) Appliance mode support value.
        - ipv6_support : (Optional | string) IPv6 support value.
    Example:
    ```
    vpc_attachments = {
      app = {
        vpc_id = "vpc-xxxxxxxx"
        zone_mappings = [
          {
            zone_id    = "cn-guangzhou-a"
            vswitch_id = "vsw-xxxxxxxx"
          },
          {
            zone_id    = "cn-guangzhou-b"
            vswitch_id = "vsw-yyyyyyyy"
          }
        ]
      }
    }
    ```
  EOF

  validation {
    condition = alltrue([
      for attachment in var.vpc_attachments : length(attachment.zone_mappings) > 0 && length(attachment.zone_mappings) <= 10
    ])
    error_message = "Each VPC attachment must define between one and ten zone_mappings."
  }
}

variable "route_table_associations" {
  type = map(object({
    route_table_key = optional(string, "")
    route_table_id  = optional(string, "")
    attachment_key  = optional(string, "")
    attachment_id   = optional(string, "")
  }))
  default     = {}
  description = <<-EOF
    Transit Router route table associations.
    Options:
      - route_table_key : (Optional | string | default:"") Key in route_tables.
      - route_table_id : (Optional | string | default:"") Explicit Transit Router route table ID. Takes precedence over route_table_key.
      - attachment_key : (Optional | string | default:"") Key in vpc_attachments.
      - attachment_id : (Optional | string | default:"") Explicit Transit Router attachment ID. Takes precedence over attachment_key.
    Example:
    ```
    route_table_associations = {
      app = {
        route_table_key = "spoke"
        attachment_key  = "app"
      }
    }
    ```
  EOF

  validation {
    condition = alltrue([
      for association in var.route_table_associations : (association.route_table_key != "" || association.route_table_id != "") && (association.attachment_key != "" || association.attachment_id != "")
    ])
    error_message = "Each route table association must set route_table_key or route_table_id, and attachment_key or attachment_id."
  }
}

variable "route_table_propagations" {
  type = map(object({
    route_table_key = optional(string, "")
    route_table_id  = optional(string, "")
    attachment_key  = optional(string, "")
    attachment_id   = optional(string, "")
  }))
  default     = {}
  description = <<-EOF
    Transit Router route table propagations.
    Options:
      - route_table_key : (Optional | string | default:"") Key in route_tables.
      - route_table_id : (Optional | string | default:"") Explicit Transit Router route table ID. Takes precedence over route_table_key.
      - attachment_key : (Optional | string | default:"") Key in vpc_attachments.
      - attachment_id : (Optional | string | default:"") Explicit Transit Router attachment ID. Takes precedence over attachment_key.
    Example:
    ```
    route_table_propagations = {
      app = {
        route_table_key = "spoke"
        attachment_key  = "app"
      }
    }
    ```
  EOF

  validation {
    condition = alltrue([
      for propagation in var.route_table_propagations : (propagation.route_table_key != "" || propagation.route_table_id != "") && (propagation.attachment_key != "" || propagation.attachment_id != "")
    ])
    error_message = "Each route table propagation must set route_table_key or route_table_id, and attachment_key or attachment_id."
  }
}

variable "route_entries" {
  type = map(object({
    route_table_key         = optional(string, "")
    route_table_id          = optional(string, "")
    destination_cidr_block  = string
    next_hop_type           = string
    next_hop_attachment_key = optional(string, "")
    next_hop_id             = optional(string, "")
    name                    = optional(string, "")
    description             = optional(string, "")
  }))
  default     = {}
  description = <<-EOF
    Static route entries in Transit Router route tables.
    Options:
      - route_table_key : (Optional | string | default:"") Key in route_tables.
      - route_table_id : (Optional | string | default:"") Explicit Transit Router route table ID. Takes precedence over route_table_key.
      - destination_cidr_block : (Required | string) Destination CIDR block.
      - next_hop_type : (Required | string) Route next hop type. Valid values: Attachment, BlackHole.
      - next_hop_attachment_key : (Optional | string | default:"") Key in vpc_attachments.
      - next_hop_id : (Optional | string | default:"") Explicit next hop attachment ID. Required when next_hop_type is Attachment and next_hop_attachment_key is empty.
      - name : (Optional | string | default:"") Route entry name. If empty, the module uses '<prefix>-<map key>'.
      - description : (Optional | string | default:"") Route entry description.
    Example:
    ```
    route_entries = {
      default_to_firewall = {
        route_table_key         = "spoke"
        destination_cidr_block  = "0.0.0.0/0"
        next_hop_type           = "Attachment"
        next_hop_attachment_key = "firewall"
      }
    }
    ```
  EOF

  validation {
    condition = alltrue([
      for route in var.route_entries : route.route_table_key != "" || route.route_table_id != ""
    ])
    error_message = "Each route entry must set route_table_key or route_table_id."
  }

  validation {
    condition = alltrue([
      for route in var.route_entries : contains(["Attachment", "BlackHole"], route.next_hop_type)
    ])
    error_message = "route entry next_hop_type must be Attachment or BlackHole."
  }

  validation {
    condition = alltrue([
      for route in var.route_entries : route.next_hop_type == "BlackHole" || route.next_hop_attachment_key != "" || route.next_hop_id != ""
    ])
    error_message = "Attachment route entries must set next_hop_attachment_key or next_hop_id."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to supported resources."
}
