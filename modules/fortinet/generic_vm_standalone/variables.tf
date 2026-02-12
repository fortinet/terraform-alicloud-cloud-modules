# [Project variables]
variable "prefix" {
  type        = string
  description = "Prefix of all objects in this module. It should be unique to avoid name conflict between projects."
}


# [Instance configuration]
variable "hostname" {
  type        = string
  default     = ""
  description = "Your predefined instance hostname. If not set, it will be <prefix>-instance by default."
}

variable "password" {
  type        = string
  default     = ""
  description = "Password for the instance. If not provided, it will be your instance ID by default."
  sensitive   = true
}

variable "description" {
  description = "Instance Description."
  type        = string
  default     = null
}

variable "instance_type" {
  type        = string
  description = "Instance Type"
}

variable "instance_charge_type" {
  type    = string
  default = "PostPaid"
  validation {
    condition     = contains(["PrePaid", "PostPaid"], var.instance_charge_type)
    error_message = "Invalid instance charge type. Must be one of: PrePaid, PostPaid."
  }
  description = <<-EOF
    Instance Charge Type. Must be one of: PrePaid (Subscription), PostPaid (Pay as you go).
  EOF
}


# [Network configuration]
variable "network_interfaces" {
  type = list(object({
    vswitch_id          = string
    private_ip          = optional(string, null)
    security_group_list = optional(list(string), [])
  }))
  description = <<-EOF
    Network Interfaces configuration. List of objects, each object is a network interface.
    Optional, if not provided, the instance will not have any network interface.


  Options:
    - vswitch_id : (Required | string) VSwitch ID.
    - private_ip : (Optional | string | default:null) Private IP. If not provided, the instance will be assigned a private IP automatically.
    - security_group_list : (Optional | list(string) | default:[]) Security Group List.

  Example:
  ```
  network_interfaces = [
    {
      vswitch_id = "vsw-1234567890"
      private_ip = "10.0.0.10"
      security_group_list = ["sg-1234567890"]
    }
  ]
  ```
  EOF
}

variable "internet_max_bandwidth_out" {
  description = "Internet Max Bandwidth Out. If set to 0, the instance will not have a public IP."
  type        = number
  default     = 0 # 0 means no public IP.
}


# [Image configuration]
variable "image" {
  type = object({
    image_id     = optional(string, "")     # Image id, e.g. "m-2ze82msjfaas58qajzh7"
    product_type = optional(string, "")     # FortiGate, FortiManager, FortiAnalyzer
    version      = optional(string, "")     # e.g. 7.6.5
    license_type = optional(string, "BYOL") # BYOL, PAYG
  })
  validation {
    condition     = var.image.image_id != "" || contains(["BYOL", "PAYG"], var.image.license_type)
    error_message = "Invalid license type. Must be one of: BYOL, PAYG."
  }
  validation {
    condition     = var.image.image_id != "" || contains(["FortiGate", "FortiManager", "FortiAnalyzer"], var.image.product_type)
    error_message = "Invalid product type. Must be one of: FortiGate, FortiManager, FortiAnalyzer."
  }
  description = <<-EOF
    Image configuration. Either image_id or product_type must be provided.
    If image_id is provided, it will be used to create the VM. Otherwise, the image will be searched by product_type, version and license_type.
  
    Options:
      - image_id : (Optional | string | default:"") Image ID. Please note, even for the same OS image, its image ID is different in different regions.
      - product_type : (Optional | string | default:"") Product type. Possible values: FortiGate, FortiManager, FortiAnalyzer.
      - version : (Optional | string | default:"") Version. Only major version is required, minor version and patch version are optional, e.g., 7, 7.6, 7.6.5.
      - license_type : (Optional | string | default:"BYOL") License type. Must be one of: BYOL, PAYG.

    Example:
    ```
    image = {
      product_type = "FortiGate"
      version = "7.6.5"
      license_type = "BYOL"
    }
    ```
    OR
    ```
    image = {
      image_id = "m-2ze82msjfaas58qajzh7"
    }
    ```
  EOF
}


# [Disk configuration]
variable "system_disk" {
  type = object({
    name              = optional(string, "")
    description       = optional(string, "")
    size              = number
    category          = string
    performance_level = optional(string, "PL1")
  })
  description = <<-EOF
    System Disk configuration.
  
    Options:
      - name : (Optional | string) System Disk name. The name must be 2 to 128 characters in length and can contain letters, digits, periods, colons, underscores, and hyphens.
      - description : (Optional | string) System Disk description.
      - size : (Required | number ) System Disk size in GB. Value range: [20, 500].
      - category : (Required | string) System Disk category. Valid values are ephemeral_ssd, cloud_efficiency, cloud_ssd, cloud_essd, cloud, cloud_auto, cloud_essd_entry.
      - performance_level : (Optional | string | default:"PL1") System Disk performance level. Valid values are PL0, PL1, PL2, PL3.

    Example:
    ```
    system_disk = {
      name = "my-system-disk"
      description = "System Disk description"
      category = "cloud_essd"
      size = 40
      performance_level = "PL1"
    }
    ```
  EOF
}

variable "data_disks" {
  type = list(object({
    name              = optional(string, "")
    description       = optional(string, "")
    size              = number
    category          = string
    performance_level = optional(string, "PL1")
  }))
  default     = []
  description = <<-EOF
    Data Disk configuration. List of objects, each object is a data disk.
    Optional, if not provided, the instance will not have any data disk.

    Options:
      - name : (Optional | string) Disk name. The name must be 2 to 128 characters in length and can contain letters, digits, periods, colons, underscores, and hyphens.
      - description : (Optional | string) Disk description.
      - size : (Required | number ) Disk size in GB. Value range: [20, 500].
      - category : (Required | string) Disk category. Valid values are ephemeral_ssd, cloud_efficiency, cloud_ssd, cloud_essd, cloud, cloud_auto.
      - performance_level : (Optional | string | default:"PL1") Disk performance level. Valid values are PL0, PL1, PL2, PL3.

    Example:
    ```
    data_disks = [{
      name = "my-data-disk"
      description = "Data Disk description"
      category = "cloud_essd"
      size = 40
      performance_level = "PL1"
    }]
    ```
  EOF
}


# [License configuration]
variable "license" {
  type = object({
    license_file    = optional(string, "")
    fortiflex_token = optional(string, "")
  })
  default     = {}
  description = <<-EOF
    If your image.license_type is byol (bring your own license), you can license your instance here.

    Options:

      - license_file : (Optional | string | default:"") Location of your own license file.
      - fortiflex_token : (Optional | string | default:"") Fortiflex token to activate VM.

    Example:
    ```
    license = {
      license_file = "/path/to/license.lic"
    }
    ```
    OR
    ```
    license = {
      fortiflex_token = "<fortiflex token>"
    }
    ```
  EOF
}


# [Custom configuration]
variable "config" {
  type = object({
    config_script = optional(string, "")
    config_file   = optional(string, "")
  })
  default     = {}
  description = <<-EOF
    If you want to add custom configuration to your instance, you can do it here.

    Options:

      - config_script : (Optional | string | default:"") Custom configuration script.
      - config_file : (Optional | string | default:"") Custom configuration file.

    Example:
    ```
    config = {
      config_script = "config system global\nset hostname FGTVM\nend"
    }
    ```
    OR
    ```
    config = {
      config_file = "/path/to/config.conf"
    }
    ```
  EOF
}


# [Resource Identification]
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
