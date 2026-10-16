variable "region" {
  type        = string
  description = "Alicloud region ID used to select the default OTS instance type."
}

variable "name" {
  type        = string
  description = "OTS instance to be created. This value is used when existing_instance_name is empty."
}

variable "existing_instance_name" {
  type        = string
  default     = ""
  description = "Existing OTS instance name. If set, the module creates tables in this instance and does not create a new OTS instance."
}

variable "instance_type" {
  type        = string
  default     = null
  nullable    = true
  description = <<-EOF
    OTS instance type.
    Options:
      - null : Select HighPerformance when supported in the region, otherwise Capacity.
      - Capacity : Capacity instance type.
      - HighPerformance : HighPerformance instance type.
    Example:
    ```
    instance_type = "Capacity"
    ```
  EOF

  validation {
    condition     = var.instance_type == null || contains(["Capacity", "HighPerformance"], var.instance_type)
    error_message = "instance_type must be Capacity or HighPerformance."
  }
}

variable "description" {
  type        = string
  default     = ""
  description = "OTS instance description."
}

variable "resource_group_id" {
  type        = string
  default     = null
  description = "Resource group ID."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to supported resources."
}

variable "tables" {
  type = list(object({
    table_name = string
    primary_key = list(object({
      name = string
      type = string
    }))
    defined_column = optional(list(object({
      name = string
      type = string
    })), [])
    time_to_live = optional(number, -1)
    max_version  = optional(number, 1)
  }))
  default     = []
  description = <<-EOF
    OTS table configuration.
    Options:
      - table_name : (Required | string) OTS table name.
      - primary_key : (Required | list(object)) Primary key schema. Each table must define between one and four primary keys.
        - name : (Required | string) Primary key column name.
        - type : (Required | string) Primary key column type. Valid values: Integer, String, Binary.
      - defined_column : (Optional | list(object) | default:[]) Defined column schema. Each table can define at most 32 defined columns.
        - name : (Required | string) Defined column name.
        - type : (Required | string) Defined column type. Valid values: Integer, String, Binary, Double, Boolean.
      - time_to_live : (Optional | number | default:-1) Data time to live in seconds. Use -1 to keep data permanently.
      - max_version : (Optional | number | default:1) Maximum number of versions to keep for each attribute column.
    Example:
    ```
    tables = [
      {
        table_name = "metadata"
        primary_key = [
          {
            name = "ID"
            type = "String"
          }
        ]
        defined_column = [
          {
            name = "State"
            type = "String"
          }
        ]
        time_to_live = -1
        max_version  = 1
      }
    ]
    ```
  EOF

  validation {
    condition     = length(var.tables) == length(distinct([for table in var.tables : table.table_name]))
    error_message = "Each table_name in tables must be unique."
  }

  validation {
    condition = alltrue([
      for table in var.tables : length(table.primary_key) >= 1 && length(table.primary_key) <= 4
    ])
    error_message = "Each table must define between one and four primary_key entries."
  }

  validation {
    condition = alltrue(flatten([
      for table in var.tables : [
        for primary_key in table.primary_key : contains(["Integer", "String", "Binary"], primary_key.type)
      ]
    ]))
    error_message = "primary_key type must be Integer, String, or Binary."
  }

  validation {
    condition = alltrue([
      for table in var.tables : length(table.defined_column) <= 32
    ])
    error_message = "Each table can define at most 32 defined_column entries."
  }

  validation {
    condition = alltrue(flatten([
      for table in var.tables : [
        for defined_column in table.defined_column : contains(["Integer", "String", "Binary", "Double", "Boolean"], defined_column.type)
      ]
    ]))
    error_message = "defined_column type must be Integer, String, Binary, Double, or Boolean."
  }
}
