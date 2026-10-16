## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0, < 2.0.0 |
| <a name="requirement_alicloud"></a> [alicloud](#requirement\_alicloud) | >= 1.277.0, < 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_alicloud"></a> [alicloud](#provider\_alicloud) | >= 1.277.0, < 2.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [alicloud_gwlb_listener.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/gwlb_listener) | resource |
| [alicloud_gwlb_load_balancer.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/gwlb_load_balancer) | resource |
| [alicloud_gwlb_server_group.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/gwlb_server_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_health_check"></a> [health\_check](#input\_health\_check) | GWLB server group health check and connection drain configuration.<br>Options:<br>  - health\_check\_enabled : (Optional \| bool \| default:true) Whether to enable health checks.<br>  - health\_check\_protocol : (Optional \| string \| default:"TCP") Health check protocol.<br>  - health\_check\_connect\_port : (Optional \| number \| default:8008) Health check port.<br>  - health\_check\_connect\_timeout : (Optional \| number \| default:5) Health check timeout in seconds.<br>  - health\_check\_interval : (Optional \| number \| default:10) Health check interval in seconds.<br>  - healthy\_threshold : (Optional \| number \| default:3) Number of successful checks required before a server is considered healthy.<br>  - unhealthy\_threshold : (Optional \| number \| default:3) Number of failed checks required before a server is considered unhealthy.<br>  - connection\_drain\_enabled : (Optional \| bool \| default:false) Whether to enable connection draining.<br>  - connection\_drain\_timeout : (Optional \| number \| default:300) Connection drain timeout in seconds.<br>Example:<pre>health_check = {<br>  health_check_enabled         = true<br>  health_check_protocol        = "TCP"<br>  health_check_connect_port    = 8008<br>  health_check_connect_timeout = 5<br>  health_check_interval        = 10<br>  healthy_threshold            = 3<br>  unhealthy_threshold          = 3<br>  connection_drain_enabled     = false<br>  connection_drain_timeout     = 300<br>}</pre> | <pre>object({<br>    health_check_enabled         = optional(bool, true)<br>    health_check_protocol        = optional(string, "TCP")<br>    health_check_connect_port    = optional(number, 8008)<br>    health_check_connect_timeout = optional(number, 5)<br>    health_check_interval        = optional(number, 10)<br>    healthy_threshold            = optional(number, 3)<br>    unhealthy_threshold          = optional(number, 3)<br>    connection_drain_enabled     = optional(bool, false)<br>    connection_drain_timeout     = optional(number, 300)<br>  })</pre> | `{}` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix of all resources in this module. Resource names are inferred from this prefix. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource group ID. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to supported resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the GWLB load balancer and server group are deployed. | `string` | n/a | yes |
| <a name="input_zone_mappings"></a> [zone\_mappings](#input\_zone\_mappings) | GWLB zone and VSwitch mappings.<br>Options:<br>  - zone\_id : (Required \| string) Zone ID where the GWLB is deployed.<br>  - vswitch\_id : (Required \| string) VSwitch ID used by the GWLB in this zone.<br>Example:<pre>zone_mappings = [<br>  {<br>    zone_id    = "cn-guangzhou-a"<br>    vswitch_id = "vsw-xxxxxxxx"<br>  }<br>]</pre> | <pre>list(object({<br>    zone_id    = string<br>    vswitch_id = string<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address"></a> [address](#output\_address) | First GWLB private IPv4 address. |
| <a name="output_addresses"></a> [addresses](#output\_addresses) | GWLB private IPv4 addresses and ENI IDs. |
| <a name="output_addresses_by_zone"></a> [addresses\_by\_zone](#output\_addresses\_by\_zone) | GWLB private IPv4 address keyed by zone ID. |
| <a name="output_id"></a> [id](#output\_id) | GWLB instance ID. |
| <a name="output_listener_id"></a> [listener\_id](#output\_listener\_id) | GWLB listener ID. |
| <a name="output_server_group_id"></a> [server\_group\_id](#output\_server\_group\_id) | GWLB server group ID. |
| <a name="output_zone_mappings"></a> [zone\_mappings](#output\_zone\_mappings) | GWLB zone mappings. |
