## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0, < 2.0.0 |
| <a name="requirement_alicloud"></a> [alicloud](#requirement\_alicloud) | >= 1.279.0, < 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_alicloud"></a> [alicloud](#provider\_alicloud) | >= 1.279.0, < 2.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [alicloud_privatelink_vpc_endpoint.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/privatelink_vpc_endpoint) | resource |
| [alicloud_privatelink_vpc_endpoint_zone.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/privatelink_vpc_endpoint_zone) | resource |
| [alicloud_route_entry.app_to_gwlbe](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/route_entry) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_endpoint_zones"></a> [endpoint\_zones](#input\_endpoint\_zones) | GWLBe VSwitch mappings keyed by zone ID. The actual zone is inferred from the VSwitch, which must belong to the corresponding zone. Each key creates one single-zone endpoint. Adding or removing another zone does not change existing endpoint resource addresses.<br>Options:<br>  - vswitch\_id : (Required \| string) Consumer-side VSwitch ID for the endpoint zone.<br>Example:<pre>endpoint_zones = {<br>  cn-guangzhou-a = {<br>    vswitch_id = "vsw-xxxxxxxx"<br>  }<br>}</pre> | <pre>map(object({<br>    vswitch_id = string<br>  }))</pre> | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix of all resources in this module. Resource names are inferred from this prefix. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource group ID. | `string` | `null` | no |
| <a name="input_route_entries"></a> [route\_entries](#input\_route\_entries) | Route entries keyed by a stable name, such as zone ID and purpose, that send consumer VPC traffic to the GWLBe.<br>Leave this map empty when route tables are managed outside this module or when only the endpoint should be created.<br>Options:<br>  - route\_table\_id : (Required \| string) Route table ID where the route entry is created.<br>  - destination\_cidrblock : (Required \| string) Destination CIDR block routed to the GWLBe.<br>  - endpoint\_zone\_key : (Required \| string) Zone ID key in endpoint\_zones used as the route next hop. Use the endpoint in the same zone as the VSwitch associated with the route table.<br>  - name : (Optional \| string \| default:"") Route entry name.<br>  - description : (Optional \| string \| default:"") Route entry description.<br>Example:<pre>route_entries = {<br>  "cn-guangzhou-a/default" = {<br>    route_table_id        = "vtb-xxxxxxxx"<br>    destination_cidrblock = "0.0.0.0/0"<br>    endpoint_zone_key     = "cn-guangzhou-a"<br>    name                  = "default-to-gwlbe"<br>    description           = "Send traffic to the GWLBe."<br>  }<br>}</pre> | <pre>map(object({<br>    route_table_id        = string<br>    destination_cidrblock = string<br>    endpoint_zone_key     = string<br>    name                  = optional(string, "")<br>    description           = optional(string, "")<br>  }))</pre> | `{}` | no |
| <a name="input_service_id"></a> [service\_id](#input\_service\_id) | PrivateLink endpoint service ID. Either service\_id or service\_name must be set. | `string` | `""` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | PrivateLink endpoint service name. Either service\_id or service\_name must be set. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to supported resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Consumer VPC ID where the GWLBe is created. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_ids"></a> [endpoint\_ids](#output\_endpoint\_ids) | GWLBe endpoint IDs keyed by zone ID. |
| <a name="output_endpoint_zones"></a> [endpoint\_zones](#output\_endpoint\_zones) | GWLBe endpoint zone resources keyed by zone ID. |
| <a name="output_route_entry_ids"></a> [route\_entry\_ids](#output\_route\_entry\_ids) | Route entry IDs keyed by the stable names supplied in route\_entries. |
