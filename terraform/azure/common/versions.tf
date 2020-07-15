terraform {
  required_version = ">= 0.13.0"
}

provider "azurerm" {
  version = "~> 2.22"
  features {}
}

provider "azurerm" {
  features {}

  subscription_id = var.arm_subscription_id
  tenant_id       = var.arm_tenant_id
  alias           = "default"
}

provider "http" {
  version = "~> 1.2"
  alias   = "default"
}

provider "null" {
  version = "~> 2.1"
  alias   = "default"
}

provider "random" {
  version = "~> 2.3"
  alias   = "default"
}

provider "template" {
  version = "~> 2.1"
  alias   = "default"
}
