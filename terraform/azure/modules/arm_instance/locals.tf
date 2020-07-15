# identify external ipv4 address of the system where terraform is being run from
data "http" "workstation-ipv4" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  workstation-ipv4-cidr = "${chomp(data.http.workstation-ipv4.body)}/32"

  arm_resource_group_name = var.arm_resource_group_name != "" ? var.arm_resource_group_name : "${var.arm_contact}-chef_infra-test"

  instance_name = "${var.name}-${replace(var.platform, ".", "")}"
  hostname      = var.hostname != "" ? var.hostname : "${replace(var.platform, ".", "")}-${replace(azurerm_network_interface.default.private_ip_address, "/^.*\\./", "")}"

  source_images = {
    rhel-6 = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "6.9"
      version   = "latest"
    }

    rhel-7 = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "7.8"
      version   = "latest"
    }

    rhel-8 = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "8.2"
      version   = "latest"
    }

    "ubuntu-16.04" = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04-LTS"
      version   = "latest"
    }

    "ubuntu-18.04" = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }

    "ubuntu-20.04" = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "20.04-LTS"
      version   = "latest"
    }

    windows-2019 = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    }

    windows-10 = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "windows-10"
      sku       = "19h2-ent"
      version   = "latest"
    }

    windows-8 = {
      publisher = "MicrosoftVisualStudio"
      offer     = "Windows"
      sku       = "Win81-Ent-N-x64"
      version   = "latest"
    }
  }
}
