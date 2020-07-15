module "chef_server" {
  source = "../../modules/arm_instance"

  arm_tenant_id           = var.arm_tenant_id
  arm_subscription_id     = var.arm_subscription_id
  arm_location            = var.arm_location
  arm_resource_group_name = var.arm_resource_group_name
  arm_department          = var.arm_department
  arm_contact             = var.arm_contact
  arm_ssh_key_file        = var.arm_ssh_key_file
  arm_instance_type       = var.arm_instance_type
  platform                = var.server_platform
  build_prefix            = var.build_prefix
  name                    = "chefserver"
  hostname                = "chefserver"
}

resource "null_resource" "chef_server_config" {
  connection {
    type = "ssh"
    user = module.chef_server.username
    host = module.chef_server.public_ipv4_address
  }

  provisioner "file" {
    source      = "${path.module}/files/chef-server.rb"
    destination = "/tmp/chef-server.rb"
  }

  provisioner "file" {
    source      = "${path.module}/../../../common/files/dhparam.pem"
    destination = "/tmp/dhparam.pem"
  }

  # install chef-server
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nBEGIN INSTALL CHEF SERVER\n'",
      "curl -vo /tmp/${replace(var.server_version_url, "/^.*\\//", "")} ${var.server_version_url}",
      "sudo ${replace(var.server_version_url, "rpm", "") != var.server_version_url ? "rpm -U" : "dpkg -iEG"} /tmp/${replace(var.server_version_url, "/^.*\\//", "")}",
      "sudo chown root:root /tmp/chef-server.rb",
      "sudo chown root:root /tmp/dhparam.pem",
      "sudo mv /tmp/chef-server.rb /etc/opscode",
      "sudo mv /tmp/dhparam.pem /etc/opscode",
      "sudo chef-server-ctl reconfigure --chef-license=accept",
      "sleep 120",
      "echo -e '\nEND INSTALL CHEF SERVER\n'",
    ]
  }

  # add user + organization
  provisioner "remote-exec" {
    script = "${path.module}/../../../common/files/add_user.sh"
  }

  # install chef manage
  provisioner "remote-exec" {
    script = "${path.module}/../../../common/files/install_addon_chef_manage.sh"
  }
}
