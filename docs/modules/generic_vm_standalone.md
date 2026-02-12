# Module: Deploy one Forti Product - generic_vm_standalone

Deploy any Forti products (e.g., FortiGate, FortiAnalyzer, FortiManager... ) and using existing VPCs.

## Example scripts
Following script creates one VPC, two vswitches (subnets), and deploys one FortiGate with two network interfaces, each in a different subnet.

```hcl
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

# Get available zones and instance types for the specified region and resource creation requirements.
data "alicloud_zones" "available_zones" {
  available_resource_creation = "Instance"
  available_disk_category     = "cloud_essd"
}

data "alicloud_instance_types" "available_instance_types" {
  availability_zone    = data.alicloud_zones.available_zones.zones[0].id
  cpu_core_count       = 2
  memory_size          = 4
  system_disk_category = "cloud_essd"
  # instance_type_family = "ecs.c7"
}

# Network
module "vpc" {
  source = "fortinetdev/cloud-modules/alicloud//modules/alicloud/vpc"
  prefix = "Example-network"

  vpc = {
    cidr = "10.0.0.0/8"
  }

  vswitch = [
    {
      zone = data.alicloud_zones.available_zones.zones[0].id
      cidr = "10.0.0.0/16"
    },
    {
      zone = data.alicloud_zones.available_zones.zones[0].id
      cidr = "10.1.0.0/16"
    }
  ]

  security_group = {
    # Allow all traffic (ingress and egress)
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

  resource_group_id = var.resource_group_id
  tags              = var.tags
}


# FortiGate
module "fgt" {
  source = "fortinetdev/cloud-modules/alicloud//modules/fortinet/generic_vm_standalone"
  prefix = "Example-FGT"

  # [Instance configuration]
  instance_type        = data.alicloud_instance_types.available_instance_types.ids[0]
  instance_charge_type = "PostPaid"
  description          = "This is a FortiGate instance" # Optional.
  password             = "YOUR_PASSWORD"                # Optional, if not provided, it will be your instance_id by default.

  # [Network configuration]
  network_interfaces = [
    {
      vswitch_id          = module.vpc.vswitch_ids[0]
      private_ip          = "10.0.0.10" # Optional, if not provided, the instance will be assigned a private IP automatically
      security_group_list = [module.vpc.security_group_id]
    },
    {
      vswitch_id          = module.vpc.vswitch_ids[1]
      private_ip          = "10.1.0.10" # Optional, if not provided, the instance will be assigned a private IP automatically
      security_group_list = [module.vpc.security_group_id]
    }
  ]
  internet_max_bandwidth_out = 10 # If set to 0, the instance will not have a public IP."

  # [Image configuration]
  # Method 1: Search image by product_type, version and license_type
  image = {
    product_type = "FortiGate" # FortiGate, FortiAnalyzer, FortiManager
    version      = "7.6"       # Only major version is required, minor version and patch version are optional, e.g., 7, 7.6, 7.6.5
    license_type = "BYOL"      # One of: BYOL, PAYG. BYOL (bring your own license), PAYG (pay as you go).
  }

  # Method 2: Specify image id
  # image = {
  #   image_id = "m-6wee5hizud0gt7a75uty" # Please note, even for the same image, the image ID is different in different regions.
  # }

  # [Disk configuration]
  system_disk = {
    category          = "cloud_essd"
    size              = 40
    performance_level = "PL1"
  }
  data_disks = [ # Optional. You can add multiple data disks or not specify this.
    {
      category          = "cloud_essd"
      size              = 60
      performance_level = "PL1"
    }
  ]

  # [License configuration]
  # Only for BYOL (bring your own license) image.
  license = {
    # license_file = "/path/to/your/license.lic"
    # fortiflex_token = "<YOUR FORTIFLEX TOKEN>"
  }

  # [Custom configuration]
  config = {
    config_script = <<-EOF
    EOF
    # config_file = "./path/to/custom_config.conf"
  }

  # [Others]
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

# Resource Identification
variable "resource_group_id" {
  description = "Resource Group ID"
  type        = string
  default     = null
}

variable "tags" {
  description = "All the resources will be tagged with this map"
  type        = map(string)
  default     = {}
}

output "vpc_info" {
  value = module.vpc
}

output "fgt_info" {
  value = module.fgt
}
```