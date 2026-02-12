output "image_id" {
  description = "Image ID."
  value = local.image_id
}

output "image_name" {
  description = "Image name. If image_id is provided, it will be the ID of the image. Otherwise, it will be the name of the image searched by product_type, version and license_type."
  value = var.image.image_id != "" ? "${var.image.image_id}" : data.alicloud_images.image[0].images[0].name
}

output "instance_id" {
  description = "Instance ID"
  value = alicloud_instance.instance.id
}

output "instance_public_ip" {
  description = "Instance Public IP for the instance's first network interface (ENI). If the instance does not have a public IP, it will be an empty string."
  value = alicloud_instance.instance.public_ip
}

output "instance_private_ips" {
  description = "Instance Private IPs for the instance's all network interfaces (ENIs)."
  value = concat([alicloud_instance.instance.primary_ip_address], [for eni in alicloud_network_interface.interfaces : eni.private_ip])
}
