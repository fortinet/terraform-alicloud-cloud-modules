<img src="https://upload.wikimedia.org/wikipedia/commons/6/62/Fortinet_logo.svg" alt="Fortinet LOGO" width="300" />

## Terraform modules for Fortinet VM products on AliCloud

Terraform modules for deploying Fortinet VM products (e.g. FortiGate VM) on AliCloud. 

Folder `modules` contains reusable modules for AliCloud configurations (Subfolder `alicloud`) and Fortinet VM products (Other subfolders). 

## Supported Templates

### Modules
1. [generic_vm_standalone](https://github.com/fortinetdev/terraform-alicloud-cloud-modules/blob/main/docs/modules/generic_vm_standalone.md)

    This module can be used to deploy any Fortinet VM: FortiGate / FortiManager / FortiAnalyzer


### Examples
1. [cen_tr_gwlb_fgt](https://github.com/fortinetdev/terraform-alicloud-cloud-modules/blob/main/docs/modules/cen_tr_gwlb_fgt.md)

    Deploy FortiGate Autoscale Group with CEN Transit Router and Gateway Load Balancer (GWLB) for outbound (north-south) and inter-VPC traffic (east-west) inspection.


## How to Use Examples/Modules:

1. Create a new folder for your project.
2. Create file "providers.tf", specify the provider version and region, for instance:
```
terraform {
  required_version = ">=1.0, < 2.0.0"
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
      version = "~> 1.0"
    }
  }
}

provider "alicloud" {
  region     = "<YOUR ALICLOUD REGION>" # Or leave it blank and use environment variable "ALIBABA_CLOUD_REGION"
  access_key = "<YOUR ALICLOUD ACCESS KEY>" # Or leave it blank and use environment variable "ALIBABA_CLOUD_ACCESS_KEY_ID"
  secret_key = "<YOUR ALICLOUD SECRET KEY>" # Or leave it blank and use environment variable "ALIBABA_CLOUD_ACCESS_KEY_SECRET"
}
```
2. Create file "main.tf", specify the source to the target module, for instance: `"fortinetdev/cloud-modules/alicloud//modules/fortinet/generic_vm_standalone"`. Provide your own values for necessary parameters of the module.

``` 
module "your_module_name" { 
    source = "fortinetdev/cloud-modules/alicloud//modules/<module_name>" 

    <Specify module variables>
} 
``` 
3. Execute the commands `terraform init` and `terraform apply`.

## Request, Question or Issue

If there is a missing feature or a bug -- [open an issue](https://github.com/fortinetdev/terraform-alicloud-cloud-modules/issues/new)

## License

[License](https://github.com/fortinetdev/terraform-alicloud-cloud-modules/blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
