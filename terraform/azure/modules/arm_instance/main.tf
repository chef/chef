data "azurerm_resource_group" "chef_resource_group" {
  name = local.arm_resource_group_name
}

data "azurerm_virtual_network" "chef_virtual_network" {
  resource_group_name = data.azurerm_resource_group.chef_resource_group.name
  name                = local.arm_resource_group_name
}

data "azurerm_subnet" "chef_subnet" {
  resource_group_name  = data.azurerm_resource_group.chef_resource_group.name
  virtual_network_name = data.azurerm_virtual_network.chef_virtual_network.name

  name = local.arm_resource_group_name
}

resource "azurerm_network_security_group" "default" {
  resource_group_name = data.azurerm_resource_group.chef_resource_group.name
  location            = data.azurerm_resource_group.chef_resource_group.location

  name = local.instance_name

  security_rule {
    name                       = "All_From_${var.arm_contact}"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.workstation-ipv4-cidr
    destination_address_prefix = "*"
  }

  tags = {
    X-Dept    = var.arm_department
    X-Contact = var.arm_contact
  }
}

resource "azurerm_public_ip" "default" {
  resource_group_name = data.azurerm_resource_group.chef_resource_group.name
  location            = data.azurerm_resource_group.chef_resource_group.location

  name = local.instance_name

  allocation_method = "Dynamic"

  tags = {
    X-Dept    = var.arm_department
    X-Contact = var.arm_contact
  }
}

resource "azurerm_network_interface" "default" {
  resource_group_name = data.azurerm_resource_group.chef_resource_group.name
  location            = data.azurerm_resource_group.chef_resource_group.location

  name = local.instance_name

  ip_configuration {
    name                          = local.instance_name
    subnet_id                     = data.azurerm_subnet.chef_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.default.id
  }

  tags = {
    X-Dept    = var.arm_department
    X-Contact = var.arm_contact
  }
}

resource "random_password" "default" {
  length           = 16
  special          = true
  override_special = "!@$%^&*_-"
}

resource "azurerm_linux_virtual_machine" "default" {
  count = length(regexall("^windows.*", var.platform)) > 0 ? 0 : 1

  resource_group_name = data.azurerm_resource_group.chef_resource_group.name
  location            = data.azurerm_resource_group.chef_resource_group.location

  name                  = local.instance_name
  computer_name         = local.hostname
  admin_username        = "azure"
  admin_password        = random_password.default.result
  size                  = var.arm_instance_type
  network_interface_ids = [azurerm_network_interface.default.id]

  admin_ssh_key {
    username   = "azure"
    public_key = file(var.arm_ssh_key_file)
  }

  os_disk {
    name                 = local.instance_name
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = lookup(local.source_images[var.platform], "publisher")
    offer     = lookup(local.source_images[var.platform], "offer")
    sku       = lookup(local.source_images[var.platform], "sku")
    version   = lookup(local.source_images[var.platform], "version")
  }

  tags = {
    X-Dept    = var.arm_department
    X-Contact = var.arm_contact
  }
}

resource "azurerm_windows_virtual_machine" "default" {
  count = length(regexall("^windows.*", var.platform)) > 0 ? 1 : 0

  resource_group_name = data.azurerm_resource_group.chef_resource_group.name
  location            = data.azurerm_resource_group.chef_resource_group.location

  name                  = local.instance_name
  computer_name         = local.hostname
  admin_username        = "azure"
  admin_password        = random_password.default.result
  size                  = var.arm_instance_type
  network_interface_ids = [azurerm_network_interface.default.id]

  os_disk {
    name                 = local.instance_name
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = lookup(local.source_images[var.platform], "publisher")
    offer     = lookup(local.source_images[var.platform], "offer")
    sku       = lookup(local.source_images[var.platform], "sku")
    version   = lookup(local.source_images[var.platform], "version")
  }

  tags = {
    X-Dept    = var.arm_department
    X-Contact = var.arm_contact
  }
}

# obtain the ip address after the public ip has been assigned to the virtual machine
data "azurerm_public_ip" "default" {
  depends_on = [azurerm_linux_virtual_machine.default, azurerm_windows_virtual_machine.default]

  resource_group_name = data.azurerm_resource_group.chef_resource_group.name

  name = local.instance_name
}
