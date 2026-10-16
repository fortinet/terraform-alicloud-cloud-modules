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
| [alicloud_cen_transit_router.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/cen_transit_router) | resource |
| [alicloud_cen_transit_router_route_entry.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/cen_transit_router_route_entry) | resource |
| [alicloud_cen_transit_router_route_table.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/cen_transit_router_route_table) | resource |
| [alicloud_cen_transit_router_route_table_association.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/cen_transit_router_route_table_association) | resource |
| [alicloud_cen_transit_router_route_table_propagation.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/cen_transit_router_route_table_propagation) | resource |
| [alicloud_cen_transit_router_vpc_attachment.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/cen_transit_router_vpc_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cen_id"></a> [cen\_id](#input\_cen\_id) | CEN instance ID where the Transit Router is created. | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Transit Router description. | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Transit Router name. If empty, the module uses '<prefix>-tr'. | `string` | `""` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix of all resources in this module. Resource names are inferred from this prefix unless specified by the user. | `string` | n/a | yes |
| <a name="input_route_entries"></a> [route\_entries](#input\_route\_entries) | Static route entries in Transit Router route tables.<br>Options:<br>  - route\_table\_key : (Optional \| string \| default:"") Key in route\_tables.<br>  - route\_table\_id : (Optional \| string \| default:"") Explicit Transit Router route table ID. Takes precedence over route\_table\_key.<br>  - destination\_cidr\_block : (Required \| string) Destination CIDR block.<br>  - next\_hop\_type : (Required \| string) Route next hop type. Valid values: Attachment, BlackHole.<br>  - next\_hop\_attachment\_key : (Optional \| string \| default:"") Key in vpc\_attachments.<br>  - next\_hop\_id : (Optional \| string \| default:"") Explicit next hop attachment ID. Required when next\_hop\_type is Attachment and next\_hop\_attachment\_key is empty.<br>  - name : (Optional \| string \| default:"") Route entry name. If empty, the module uses '<prefix>-<map key>'.<br>  - description : (Optional \| string \| default:"") Route entry description.<br>Example:<pre>route_entries = {<br>  default_to_firewall = {<br>    route_table_key         = "spoke"<br>    destination_cidr_block  = "0.0.0.0/0"<br>    next_hop_type           = "Attachment"<br>    next_hop_attachment_key = "firewall"<br>  }<br>}</pre> | <pre>map(object({<br>    route_table_key         = optional(string, "")<br>    route_table_id          = optional(string, "")<br>    destination_cidr_block  = string<br>    next_hop_type           = string<br>    next_hop_attachment_key = optional(string, "")<br>    next_hop_id             = optional(string, "")<br>    name                    = optional(string, "")<br>    description             = optional(string, "")<br>  }))</pre> | `{}` | no |
| <a name="input_route_table_associations"></a> [route\_table\_associations](#input\_route\_table\_associations) | Transit Router route table associations.<br>Options:<br>  - route\_table\_key : (Optional \| string \| default:"") Key in route\_tables.<br>  - route\_table\_id : (Optional \| string \| default:"") Explicit Transit Router route table ID. Takes precedence over route\_table\_key.<br>  - attachment\_key : (Optional \| string \| default:"") Key in vpc\_attachments.<br>  - attachment\_id : (Optional \| string \| default:"") Explicit Transit Router attachment ID. Takes precedence over attachment\_key.<br>Example:<pre>route_table_associations = {<br>  app = {<br>    route_table_key = "spoke"<br>    attachment_key  = "app"<br>  }<br>}</pre> | <pre>map(object({<br>    route_table_key = optional(string, "")<br>    route_table_id  = optional(string, "")<br>    attachment_key  = optional(string, "")<br>    attachment_id   = optional(string, "")<br>  }))</pre> | `{}` | no |
| <a name="input_route_table_propagations"></a> [route\_table\_propagations](#input\_route\_table\_propagations) | Transit Router route table propagations.<br>Options:<br>  - route\_table\_key : (Optional \| string \| default:"") Key in route\_tables.<br>  - route\_table\_id : (Optional \| string \| default:"") Explicit Transit Router route table ID. Takes precedence over route\_table\_key.<br>  - attachment\_key : (Optional \| string \| default:"") Key in vpc\_attachments.<br>  - attachment\_id : (Optional \| string \| default:"") Explicit Transit Router attachment ID. Takes precedence over attachment\_key.<br>Example:<pre>route_table_propagations = {<br>  app = {<br>    route_table_key = "spoke"<br>    attachment_key  = "app"<br>  }<br>}</pre> | <pre>map(object({<br>    route_table_key = optional(string, "")<br>    route_table_id  = optional(string, "")<br>    attachment_key  = optional(string, "")<br>    attachment_id   = optional(string, "")<br>  }))</pre> | `{}` | no |
| <a name="input_route_tables"></a> [route\_tables](#input\_route\_tables) | Transit Router route tables to create.<br>Options:<br>  - name : (Optional \| string \| default:"") Route table name. If empty, the module uses '<prefix>-<map key>'.<br>  - description : (Optional \| string \| default:"") Route table description.<br>Example:<pre>route_tables = {<br>  spoke = {}<br>  inspection = {<br>    description = "Routes for inspected traffic"<br>  }<br>}</pre> | <pre>map(object({<br>    name        = optional(string, "")<br>    description = optional(string, "")<br>  }))</pre> | `{}` | no |
| <a name="input_support_multicast"></a> [support\_multicast](#input\_support\_multicast) | Whether to enable multicast for the Enterprise Edition Transit Router. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to supported resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_attachments"></a> [vpc\_attachments](#input\_vpc\_attachments) | VPC attachments to create on the Transit Router.<br>Options:<br>  - vpc\_id : (Required \| string) VPC ID to attach.<br>  - zone\_mappings : (Required \| list(object)) Zone and VSwitch mappings for the VPC attachment. Up to 10 mappings are supported by the API.<br>    - zone\_id : (Required \| string) Zone ID supported by the Enterprise Edition Transit Router.<br>    - vswitch\_id : (Required \| string) VSwitch ID used by this VPC attachment in the zone.<br>  - name : (Optional \| string \| default:"") VPC attachment name. If empty, the module uses '<prefix>-<map key>'.<br>  - description : (Optional \| string \| default:"") VPC attachment description.<br>  - auto\_publish\_route\_enabled : (Optional \| bool \| default:false) Whether the Transit Router automatically advertises routes to the VPC.<br>  - force\_delete : (Optional \| bool \| default:false) Whether to forcibly delete related association and propagation dependencies when deleting the attachment.<br>  - order\_type : (Optional \| string) Payer of the attachment fees. Valid values: PayByCenOwner, PayByResourceOwner.<br>  - payment\_type : (Optional \| string) Billing method. Leave null to use the provider default.<br>  - options : (Optional \| object) Feature options for the VPC attachment.<br>    - appliance\_mode\_support : (Optional \| string) Appliance mode support value.<br>    - ipv6\_support : (Optional \| string) IPv6 support value.<br>Example:<pre>vpc_attachments = {<br>  app = {<br>    vpc_id = "vpc-xxxxxxxx"<br>    zone_mappings = [<br>      {<br>        zone_id    = "cn-guangzhou-a"<br>        vswitch_id = "vsw-xxxxxxxx"<br>      },<br>      {<br>        zone_id    = "cn-guangzhou-b"<br>        vswitch_id = "vsw-yyyyyyyy"<br>      }<br>    ]<br>  }<br>}</pre> | <pre>map(object({<br>    vpc_id                     = string<br>    zone_mappings              = list(object({ zone_id = string, vswitch_id = string }))<br>    name                       = optional(string, "")<br>    description                = optional(string, "")<br>    auto_publish_route_enabled = optional(bool, false)<br>    force_delete               = optional(bool, false)<br>    order_type                 = optional(string)<br>    payment_type               = optional(string)<br>    options = optional(object({<br>      appliance_mode_support = optional(string)<br>      ipv6_support           = optional(string)<br>    }))<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_attachment_ids"></a> [attachment\_ids](#output\_attachment\_ids) | Transit Router attachment IDs. |
| <a name="output_id"></a> [id](#output\_id) | Transit Router ID. |
| <a name="output_route_entry_ids"></a> [route\_entry\_ids](#output\_route\_entry\_ids) | Transit Router route entry IDs. |
| <a name="output_route_table_association_ids"></a> [route\_table\_association\_ids](#output\_route\_table\_association\_ids) | Transit Router route table association IDs. |
| <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids) | Transit Router route table IDs. |
| <a name="output_route_table_propagation_ids"></a> [route\_table\_propagation\_ids](#output\_route\_table\_propagation\_ids) | Transit Router route table propagation IDs. |
| <a name="output_vpc_attachment_ids"></a> [vpc\_attachment\_ids](#output\_vpc\_attachment\_ids) | Transit Router VPC attachment IDs. |
