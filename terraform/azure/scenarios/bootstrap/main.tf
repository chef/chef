module "workstation" {
  source = "../../modules/arm_instance"

  providers = {
    azurerm  = azurerm.default
    http     = http.default
    null     = null.default
    template = template.default
  }

  arm_tenant_id           = var.arm_tenant_id
  arm_subscription_id     = var.arm_subscription_id
  arm_location            = var.arm_location
  arm_resource_group_name = var.arm_resource_group_name
  arm_department          = var.arm_department
  arm_contact             = var.arm_contact
  arm_ssh_key_file        = var.arm_ssh_key_file
  arm_instance_type       = var.arm_instance_type
  platform                = var.workstation_platform
  build_prefix            = var.build_prefix
  name                    = "workstation-${var.scenario}"
}

module "node" {
  source = "../../modules/arm_instance"

  for_each = var.node_platforms

  providers = {
    azurerm  = azurerm.default
    http     = http.default
    null     = null.default
    template = template.default
  }

  arm_tenant_id           = var.arm_tenant_id
  arm_subscription_id     = var.arm_subscription_id
  arm_location            = var.arm_location
  arm_resource_group_name = var.arm_resource_group_name
  arm_department          = var.arm_department
  arm_contact             = var.arm_contact
  arm_ssh_key_file        = var.arm_ssh_key_file
  arm_instance_type       = var.arm_instance_type
  platform                = each.value
  build_prefix            = var.build_prefix
  name                    = "node-${replace(var.workstation_platform, ".", "")}-${var.scenario}"
}

resource "null_resource" "linux_workstation_config" {
  count = length(regexall("^windows.*", var.workstation_platform)) > 0 ? 0 : 1

  # provide some connection info
  connection {
    type = "ssh"
    user = module.workstation.username
    host = module.workstation.public_ipv4_address
  }

  # install chef-infra
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nBEGIN INSTALL CHEF INFRA\n'",
      "curl -vo /tmp/${replace(var.client_version_url, "/^.*\\//", "")} ${var.client_version_url}",
      "sudo ${replace(var.client_version_url, "rpm", "") != var.client_version_url ? "rpm -U" : "dpkg -iEG"} /tmp/${replace(var.client_version_url, "/^.*\\//", "")}",
      "scp -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' azure@chefserver:janedoe.pem /home/${module.workstation.username}",
      "knife configure --server-url 'https://chefserver.${module.workstation.private_ipv4_domain}/organizations/4thcoffee' --user janedoe --key /home/${module.workstation.username}/janedoe.pem --yes",
      "knife ssl fetch",
      "knife ssl check",
      "echo -e '\nEND INSTALL CHEF INFRA\n'",
    ]
  }
}

resource "null_resource" "windows_workstation_config" {
  count = length(regexall("^windows.*", var.workstation_platform)) > 0 ? 1 : 0

  # provide some connection info
  connection {
    type     = "winrm"
    user     = module.workstation.username
    password = module.workstation.password
    host     = module.workstation.public_ipv4_address
  }

  # install chef-infra
  provisioner "remote-exec" {
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "Write-Output '\nBEGIN INSTALL CHEF INFRA\n'",
      "Write-Output '\nEND INSTALL CHEF INFRA\n'",
    ]
  }
}

resource "null_resource" "workstation_test" {
  depends_on = [null_resource.linux_workstation_config, null_resource.windows_workstation_config]

  # only test against non-windows nodes
  for_each = toset([
    for platform in var.node_platforms :
    platform if length(regexall("^windows.*", platform)) == 0
  ])

  connection {
    type = "ssh"
    user = module.workstation.username
    host = module.workstation.public_ipv4_address
  }

  # bootstrap node
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nBEGIN BOOTSTRAP NODE\n'",
      "CHEF_LICENSE='accept' knife bootstrap ${module.node[each.value].private_ipv4_fqdn} --connection-user ${module.node[each.value].username} --sudo --node-name ${module.node[each.value].hostname} --bootstrap-version ${var.client_version} --yes",
      "echo -e '\nEND BOOTSTRAP NODE\n'",
    ]
  }

  # verify bootstrapped node
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nVERIFY BOOTSTRAP NODE\n'",
      "knife node show ${module.node[each.value].hostname}",
      "knife ssh 'name:${module.node[each.value].hostname}' uptime --ssh-user ${module.node[each.value].username}",
      "knife search 'name:${module.node[each.value].hostname}'",
      "knife node delete ${module.node[each.value].hostname} --yes",
      "knife client delete ${module.node[each.value].hostname} --yes",
      "echo -e '\nVERIFY BOOTSTRAP NODE\n'",
    ]
  }
}

resource "null_resource" "linux_node_test" {
  depends_on = [null_resource.workstation_test]

  # only test against non-windows nodes
  for_each = toset([
    for platform in var.node_platforms :
    platform if length(regexall("^windows.*", platform)) == 0
  ])

  connection {
    type = "ssh"
    user = module.node[each.value].username
    host = module.node[each.value].public_ipv4_address
  }

  # verify node commands
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nVERIFY NODE COMMANDS\n'",
      "echo -n 'OHAI OUTPUT: '",
      "ohai | wc -l",
      "echo -e '\nVERIFY NODE COMMANDS\n'",
    ]
  }
}
