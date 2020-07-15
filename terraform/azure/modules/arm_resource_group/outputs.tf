output "resource_group_id" {
  value = azurerm_resource_group.default.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.default.id
}

output "virtual_network_address_space" {
  value = azurerm_virtual_network.default.address_space
}
