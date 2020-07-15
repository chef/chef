locals {
  arm_resource_group_name = var.arm_resource_group_name != "" ? var.arm_resource_group_name : "${var.arm_contact}-chef_infra-test"
}
