# Project vars
variable "prefix" {
  type        = string
  description = "Prefix of all resources in this module. The resource name will be inferred by prefix unless specified by the user."
}

variable "vpc" {
  type = object({
    name        = optional(string, "")
    description = optional(string, "")
    cidr        = string
  })
  description = <<-EOF
    VPC configuration.
    Options:
      - name : (Optional | string) VPC name.
      - description : (Optional | string) VPC description.
      - cidr : (Required | string) VPC CIDR block.
    Example:
    ```
    vpc = {
      cidr = "10.0.0.0/8"
      # name = "my-vpc"
      # description = "VPC description"
    }
    ```
  EOF
}

variable "vswitch" {
  type = list(object({
    name        = optional(string, "")
    description = optional(string, "")
    zone        = string
    cidr        = string
  }))
  default     = []
  description = <<-EOF
    VSwitch configuration.
    Options:
      - name : (Optional | string) VSwitch name.
      - description : (Optional | string) VSwitch description.
      - zone : (Required | string) Zone ID.
      - cidr : (Required | string) VSwitch CIDR block.
    Example:
    ```
    vswitch = [
      {
        zone = "cn-guangzhou-a"
        cidr = "10.0.0.0/16"
        # name = "my-vswitch-1" # Optional
        # description = "VSwitch description 1" # Optional
      },
      {
        zone = "cn-guangzhou-b"
        cidr = "10.1.0.0/16"
        # name = "my-vswitch-2" # Optional
        # description = "VSwitch description 2" # Optional
      }
    ]
    ```
  EOF
  validation {
    condition     = length(distinct([for vswitch in var.vswitch : "${vswitch.zone}/${vswitch.cidr}"])) == length(var.vswitch)
    error_message = "Each VSwitch must have a unique zone and CIDR combination."
  }
}

variable "security_group" {
  type = object({
    name        = optional(string, "")
    description = optional(string, "")
    rules = optional(list(object({
      type        = string
      description = optional(string, "")
      ip_protocol = string
      policy      = optional(string, "accept")
      port_range  = optional(string, "-1/-1")
      priority    = optional(number, 1)
      cidr_ip     = optional(string, "0.0.0.0/0")
    })))
  })
  default = {
    rules = []
  }
  description = <<-EOF
    Security Group configuration.
    Options:
      - name : (Optional | string) Security Group name.
      - description : (Optional | string) Security Group description.
      - rules : (Optional | list(object)) Security Group rules.
        - type : (Required | string) Rule type. Valid values: ingress, egress.
        - description : (Optional | string | default:"") Rule description.
        - ip_protocol : (Required | string) Rule IP protocol. Valid values: tcp, udp, icmp, icmpv6, gre, all
        - policy : (Optional | string | default:"accept") Rule policy. Valid values: accept, drop.
        - port_range : (Optional | string | default:"-1/-1") Rule port range. The range of port numbers relevant to the IP protocol. 
        - priority : (Optional | number | default:1) Rule priority. Valid values: 1 to 100.
        - cidr_ip : (Optional | string | default:"0.0.0.0/0") IPv4 CIDR block for the rule.
    Example:
    ```
    security_group = {
      # name = "my-security-group" # Optional
      # description = "Security Group description" # Optional
      rules = [
        {
          type = "ingress"
          ip_protocol = "tcp"
          port_range = "80/80"
          policy = "accept"
          cidr_ip = "0.0.0.0/0"
          description = "Allow HTTP traffic"
        }
      ]
    }
    ```
    OR
    ```
    security_group = {
      rules = [
        {
          type        = "ingress"
          ip_protocol = "all"
          policy      = "accept"
          description = "Allow all traffic (ingress)"
        },
        {
          type        = "egress"
          ip_protocol = "all"
          policy      = "accept"
          description = "Allow all traffic (egress)"
        }
      ]
    }
    ```
    EOF
}

# Resource Identification
variable "resource_group_id" {
  description = "Resource Group ID"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to supported resources."
  type        = map(string)
  default     = {}
}
