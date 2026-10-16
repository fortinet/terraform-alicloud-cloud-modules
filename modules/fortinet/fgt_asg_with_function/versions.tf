terraform {
  required_version = ">=1.5, < 2.0.0"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.261.0, < 2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}
