output "name" {
  value = var.name
}

output "hostname" {
  value = local.hostname
}

output "resource_group_name" {
  value = data.azurerm_resource_group.chef_resource_group.name
}

output "location" {
  value = data.azurerm_resource_group.chef_resource_group.location
}

output "public_ipv4_address" {
  value = data.azurerm_public_ip.default.ip_address
}

output "private_ipv4_address" {
  value = azurerm_network_interface.default.private_ip_address
}

output "private_ipv4_domain" {
  value = azurerm_network_interface.default.internal_domain_name_suffix
}

output "private_ipv4_fqdn" {
  value = "${local.hostname}.${azurerm_network_interface.default.internal_domain_name_suffix}"
}

output "username" {
  value = "azure"
}

output "password" {
  value = random_password.default.result
}
