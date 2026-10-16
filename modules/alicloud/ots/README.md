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
| [alicloud_ots_instance.database](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/ots_instance) | resource |
| [alicloud_ots_table.tables](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/ots_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | OTS instance description. | `string` | `""` | no |
| <a name="input_existing_instance_name"></a> [existing\_instance\_name](#input\_existing\_instance\_name) | Existing OTS instance name. If set, the module creates tables in this instance and does not create a new OTS instance. | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | OTS instance type.<br>Options:<br>  - null : Select HighPerformance when supported in the region, otherwise Capacity.<br>  - Capacity : Capacity instance type.<br>  - HighPerformance : HighPerformance instance type.<br>Example:<pre>instance_type = "Capacity"</pre> | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | OTS instance to be created. This value is used when existing\_instance\_name is empty. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Alicloud region ID used to select the default OTS instance type. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource group ID. | `string` | `null` | no |
| <a name="input_tables"></a> [tables](#input\_tables) | OTS table configuration.<br>Options:<br>  - table\_name : (Required \| string) OTS table name.<br>  - primary\_key : (Required \| list(object)) Primary key schema. Each table must define between one and four primary keys.<br>    - name : (Required \| string) Primary key column name.<br>    - type : (Required \| string) Primary key column type. Valid values: Integer, String, Binary.<br>  - defined\_column : (Optional \| list(object) \| default:[]) Defined column schema. Each table can define at most 32 defined columns.<br>    - name : (Required \| string) Defined column name.<br>    - type : (Required \| string) Defined column type. Valid values: Integer, String, Binary, Double, Boolean.<br>  - time\_to\_live : (Optional \| number \| default:-1) Data time to live in seconds. Use -1 to keep data permanently.<br>  - max\_version : (Optional \| number \| default:1) Maximum number of versions to keep for each attribute column.<br>Example:<pre>tables = [<br>  {<br>    table_name = "metadata"<br>    primary_key = [<br>      {<br>        name = "ID"<br>        type = "String"<br>      }<br>    ]<br>    defined_column = [<br>      {<br>        name = "State"<br>        type = "String"<br>      }<br>    ]<br>    time_to_live = -1<br>    max_version  = 1<br>  }<br>]</pre> | <pre>list(object({<br>    table_name = string<br>    primary_key = list(object({<br>      name = string<br>      type = string<br>    }))<br>    defined_column = optional(list(object({<br>      name = string<br>      type = string<br>    })), [])<br>    time_to_live = optional(number, -1)<br>    max_version  = optional(number, 1)<br>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to supported resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | OTS instance ID. |
| <a name="output_instance_type"></a> [instance\_type](#output\_instance\_type) | OTS instance type. |
| <a name="output_name"></a> [name](#output\_name) | OTS instance name. |
| <a name="output_table_ids"></a> [table\_ids](#output\_table\_ids) | OTS table IDs. |
| <a name="output_table_names"></a> [table\_names](#output\_table\_names) | OTS table names. |
