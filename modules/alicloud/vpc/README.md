## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0, < 2.0.0 |
| <a name="requirement_alicloud"></a> [alicloud](#requirement\_alicloud) | >= 1.245.0, < 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_alicloud"></a> [alicloud](#provider\_alicloud) | >= 1.245.0, < 2.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [alicloud_security_group.security_group](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/security_group) | resource |
| [alicloud_security_group_rule.security_group_rules](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/security_group_rule) | resource |
| [alicloud_vpc.vpc](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vpc) | resource |
| [alicloud_vswitch.vswitch](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vswitch) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix of all resources in this module. The resource name will be inferred by prefix unless specified by the user. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource Group ID | `string` | `null` | no |
| <a name="input_security_group"></a> [security\_group](#input\_security\_group) | Security Group configuration.<br>Options:<br>  - name : (Optional \| string) Security Group name.<br>  - description : (Optional \| string) Security Group description.<br>  - rules : (Optional \| list(object)) Security Group rules.<br>    - type : (Required \| string) Rule type. Valid values: ingress, egress.<br>    - description : (Optional \| string \| default:"") Rule description.<br>    - ip\_protocol : (Required \| string) Rule IP protocol. Valid values: tcp, udp, icmp, icmpv6, gre, all<br>    - policy : (Optional \| string \| default:"accept") Rule policy. Valid values: accept, drop.<br>    - port\_range : (Optional \| string \| default:"-1/-1") Rule port range. The range of port numbers relevant to the IP protocol. <br>    - priority : (Optional \| number \| default:1) Rule priority. Valid values: 1 to 100.<br>    - cidr\_ip : (Optional \| string \| default:"0.0.0.0/0") IPv4 CIDR block for the rule.<br>Example:<pre>security_group = {<br>  # name = "my-security-group" # Optional<br>  # description = "Security Group description" # Optional<br>  rules = [<br>    {<br>      type = "ingress"<br>      ip_protocol = "tcp"<br>      port_range = "80/80"<br>      policy = "accept"<br>      cidr_ip = "0.0.0.0/0"<br>      description = "Allow HTTP traffic"<br>    }<br>  ]<br>}</pre>OR<pre>security_group = {<br>  rules = [<br>    {<br>      type        = "ingress"<br>      ip_protocol = "all"<br>      policy      = "accept"<br>      description = "Allow all traffic (ingress)"<br>    },<br>    {<br>      type        = "egress"<br>      ip_protocol = "all"<br>      policy      = "accept"<br>      description = "Allow all traffic (egress)"<br>    }<br>  ]<br>}</pre> | <pre>object({<br>    name        = optional(string, "")<br>    description = optional(string, "")<br>    rules = optional(list(object({<br>      type        = string<br>      description = optional(string, "")<br>      ip_protocol = string<br>      policy      = optional(string, "accept")<br>      port_range  = optional(string, "-1/-1")<br>      priority    = optional(number, 1)<br>      cidr_ip     = optional(string, "0.0.0.0/0")<br>    })))<br>  })</pre> | <pre>{<br>  "rules": []<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to supported resources. | `map(string)` | `{}` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | VPC configuration.<br>Options:<br>  - name : (Optional \| string) VPC name.<br>  - description : (Optional \| string) VPC description.<br>  - cidr : (Required \| string) VPC CIDR block.<br>Example:<pre>vpc = {<br>  cidr = "10.0.0.0/8"<br>  # name = "my-vpc"<br>  # description = "VPC description"<br>}</pre> | <pre>object({<br>    name        = optional(string, "")<br>    description = optional(string, "")<br>    cidr        = string<br>  })</pre> | n/a | yes |
| <a name="input_vswitch"></a> [vswitch](#input\_vswitch) | VSwitch configuration.<br>Options:<br>  - name : (Optional \| string) VSwitch name.<br>  - description : (Optional \| string) VSwitch description.<br>  - zone : (Required \| string) Zone ID.<br>  - cidr : (Required \| string) VSwitch CIDR block.<br>Example:<pre>vswitch = [<br>  {<br>    zone = "cn-guangzhou-a"<br>    cidr = "10.0.0.0/16"<br>    # name = "my-vswitch-1" # Optional<br>    # description = "VSwitch description 1" # Optional<br>  },<br>  {<br>    zone = "cn-guangzhou-b"<br>    cidr = "10.1.0.0/16"<br>    # name = "my-vswitch-2" # Optional<br>    # description = "VSwitch description 2" # Optional<br>  }<br>]</pre> | <pre>list(object({<br>    name        = optional(string, "")<br>    description = optional(string, "")<br>    zone        = string<br>    cidr        = string<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | Default route table ID |
| <a name="output_router_id"></a> [router\_id](#output\_router\_id) | VRouter ID |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security Group ID |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
| <a name="output_vswitch_ids"></a> [vswitch\_ids](#output\_vswitch\_ids) | VSwitch IDs in the same order as the vswitch input list. |
| <a name="output_vswitch_ids_by_zone_cidr"></a> [vswitch\_ids\_by\_zone\_cidr](#output\_vswitch\_ids\_by\_zone\_cidr) | VSwitch IDs keyed by zone ID and CIDR block, such as cn-guangzhou-a/10.0.0.0/16. |
