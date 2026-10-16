terraform {
  required_version = ">=1.9, < 2.0.0"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.285.0, < 2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

provider "alicloud" {
  region     = var.region
  access_key = var.access_key != "" ? var.access_key : null
  secret_key = var.secret_key != "" ? var.secret_key : null
}
