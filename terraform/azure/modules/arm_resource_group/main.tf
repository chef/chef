resource "azurerm_resource_group" "default" {
  name     = local.arm_resource_group_name
  location = var.arm_location

  tags = {
    X-Dept    = var.arm_department
    X-Contact = var.arm_contact
  }
}

resource "azurerm_virtual_network" "default" {
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  name          = local.arm_resource_group_name
  address_space = ["10.0.0.0/16"]

  tags = {
    X-Dept    = var.arm_department
    X-Contact = var.arm_contact
  }
}

resource "azurerm_subnet" "default" {
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name

  name             = local.arm_resource_group_name
  address_prefixes = ["10.0.1.0/24"]
}
