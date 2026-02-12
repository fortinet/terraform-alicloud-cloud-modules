## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0, < 2.0.0 |
| <a name="requirement_alicloud"></a> [alicloud](#requirement\_alicloud) | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_alicloud"></a> [alicloud](#provider\_alicloud) | ~> 1.0 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [alicloud_instance.instance](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/instance) | resource |
| [alicloud_network_interface.interfaces](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/network_interface) | resource |
| [alicloud_network_interface_attachment.eni_attach](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/network_interface_attachment) | resource |
| [alicloud_images.image](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/data-sources/images) | data source |
| [template_file.cloudinit_config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | If you want to add custom configuration to your instance, you can do it here.<br><br>Options:<br><br>  - config\_script : (Optional \| string \| default:"") Custom configuration script.<br>  - config\_file : (Optional \| string \| default:"") Custom configuration file.<br><br>Example:<pre>config = {<br>  config_script = "config system global\nset hostname FGTVM\nend"<br>}</pre>OR<pre>config = {<br>  config_file = "/path/to/config.conf"<br>}</pre> | <pre>object({<br>    config_script = optional(string, "")<br>    config_file   = optional(string, "")<br>  })</pre> | `{}` | no |
| <a name="input_data_disks"></a> [data\_disks](#input\_data\_disks) | Data Disk configuration. List of objects, each object is a data disk.<br>Optional, if not provided, the instance will not have any data disk.<br><br>Options:<br>  - name : (Optional \| string) Disk name. The name must be 2 to 128 characters in length and can contain letters, digits, periods, colons, underscores, and hyphens.<br>  - description : (Optional \| string) Disk description.<br>  - size : (Required \| number ) Disk size in GB. Value range: [20, 500].<br>  - category : (Required \| string) Disk category. Valid values are ephemeral\_ssd, cloud\_efficiency, cloud\_ssd, cloud\_essd, cloud, cloud\_auto.<br>  - performance\_level : (Optional \| string \| default:"PL1") Disk performance level. Valid values are PL0, PL1, PL2, PL3.<br><br>Example:<pre>data_disks = [{<br>  name = "my-data-disk"<br>  description = "Data Disk description"<br>  category = "cloud_essd"<br>  size = 40<br>  performance_level = "PL1"<br>}]</pre> | <pre>list(object({<br>    name              = optional(string, "")<br>    description       = optional(string, "")<br>    size              = number<br>    category          = string<br>    performance_level = optional(string, "PL1")<br>  }))</pre> | `[]` | no |
| <a name="input_description"></a> [description](#input\_description) | Instance Description. | `string` | `null` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Your predefined instance hostname. If not set, it will be <prefix>-instance by default. | `string` | `""` | no |
| <a name="input_image"></a> [image](#input\_image) | Image configuration. Either image\_id or product\_type must be provided.<br>If image\_id is provided, it will be used to create the VM. Otherwise, the image will be searched by product\_type, version and license\_type.<br><br>Options:<br>  - image\_id : (Optional \| string \| default:"") Image ID. Please note, even for the same OS image, its image ID is different in different regions.<br>  - product\_type : (Optional \| string \| default:"") Product type. Possible values: FortiGate, FortiManager, FortiAnalyzer.<br>  - version : (Optional \| string \| default:"") Version. Only major version is required, minor version and patch version are optional, e.g., 7, 7.6, 7.6.5.<br>  - license\_type : (Optional \| string \| default:"BYOL") License type. Must be one of: BYOL, PAYG.<br><br>Example:<pre>image = {<br>  product_type = "FortiGate"<br>  version = "7.6.5"<br>  license_type = "BYOL"<br>}</pre>OR<pre>image = {<br>  image_id = "m-2ze82msjfaas58qajzh7"<br>}</pre> | <pre>object({<br>    image_id     = optional(string, "")     # Image id, e.g. "m-2ze82msjfaas58qajzh7"<br>    product_type = optional(string, "")     # FortiGate, FortiManager, FortiAnalyzer<br>    version      = optional(string, "")     # e.g. 7.6.5<br>    license_type = optional(string, "BYOL") # BYOL, PAYG<br>  })</pre> | n/a | yes |
| <a name="input_instance_charge_type"></a> [instance\_charge\_type](#input\_instance\_charge\_type) | Instance Charge Type. Must be one of: PrePaid (Subscription), PostPaid (Pay as you go). | `string` | `"PostPaid"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance Type | `string` | n/a | yes |
| <a name="input_internet_max_bandwidth_out"></a> [internet\_max\_bandwidth\_out](#input\_internet\_max\_bandwidth\_out) | Internet Max Bandwidth Out. If set to 0, the instance will not have a public IP. | `number` | `0` | no |
| <a name="input_license"></a> [license](#input\_license) | If your image.license\_type is byol (bring your own license), you can license your instance here.<br><br>Options:<br><br>  - license\_file : (Optional \| string \| default:"") Location of your own license file.<br>  - fortiflex\_token : (Optional \| string \| default:"") Fortiflex token to activate VM.<br><br>Example:<pre>license = {<br>  license_file = "/path/to/license.lic"<br>}</pre>OR<pre>license = {<br>  fortiflex_token = "<fortiflex token>"<br>}</pre> | <pre>object({<br>    license_file    = optional(string, "")<br>    fortiflex_token = optional(string, "")<br>  })</pre> | `{}` | no |
| <a name="input_network_interfaces"></a> [network\_interfaces](#input\_network\_interfaces) | Network Interfaces configuration. List of objects, each object is a network interface.<br>  Optional, if not provided, the instance will not have any network interface.<br><br><br>Options:<br>  - vswitch\_id : (Required \| string) VSwitch ID.<br>  - private\_ip : (Optional \| string \| default:null) Private IP. If not provided, the instance will be assigned a private IP automatically.<br>  - security\_group\_list : (Optional \| list(string) \| default:[]) Security Group List.<br><br>Example:<pre>network_interfaces = [<br>  {<br>    vswitch_id = "vsw-1234567890"<br>    private_ip = "10.0.0.10"<br>    security_group_list = ["sg-1234567890"]<br>  }<br>]</pre> | <pre>list(object({<br>    vswitch_id          = string<br>    private_ip          = optional(string, null)<br>    security_group_list = optional(list(string), [])<br>  }))</pre> | n/a | yes |
| <a name="input_password"></a> [password](#input\_password) | Password for the instance. If not provided, it will be your instance ID by default. | `string` | `""` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix of all objects in this module. It should be unique to avoid name conflict between projects. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource Group ID | `string` | `null` | no |
| <a name="input_system_disk"></a> [system\_disk](#input\_system\_disk) | System Disk configuration.<br><br>Options:<br>  - name : (Optional \| string) System Disk name. The name must be 2 to 128 characters in length and can contain letters, digits, periods, colons, underscores, and hyphens.<br>  - description : (Optional \| string) System Disk description.<br>  - size : (Required \| number ) System Disk size in GB. Value range: [20, 500].<br>  - category : (Required \| string) System Disk category. Valid values are ephemeral\_ssd, cloud\_efficiency, cloud\_ssd, cloud\_essd, cloud, cloud\_auto, cloud\_essd\_entry.<br>  - performance\_level : (Optional \| string \| default:"PL1") System Disk performance level. Valid values are PL0, PL1, PL2, PL3.<br><br>Example:<pre>system_disk = {<br>  name = "my-system-disk"<br>  description = "System Disk description"<br>  category = "cloud_essd"<br>  size = 40<br>  performance_level = "PL1"<br>}</pre> | <pre>object({<br>    name              = optional(string, "")<br>    description       = optional(string, "")<br>    size              = number<br>    category          = string<br>    performance_level = optional(string, "PL1")<br>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | All the resources will be tagged with this map | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_image_id"></a> [image\_id](#output\_image\_id) | Image ID. |
| <a name="output_image_name"></a> [image\_name](#output\_image\_name) | Image name. If image\_id is provided, it will be the ID of the image. Otherwise, it will be the name of the image searched by product\_type, version and license\_type. |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | Instance ID |
| <a name="output_instance_private_ips"></a> [instance\_private\_ips](#output\_instance\_private\_ips) | Instance Private IPs for the instance's all network interfaces (ENIs). |
| <a name="output_instance_public_ip"></a> [instance\_public\_ip](#output\_instance\_public\_ip) | Instance Public IP for the instance's first network interface (ENI). If the instance does not have a public IP, it will be an empty string. |
