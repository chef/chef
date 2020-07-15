# default tenant is "Chef (getchef.onmicrosoft.com)"
variable "arm_tenant_id" {
  type        = string
  description = "Unique identifier of the Azure tenant used for authentication."
  default     = "a2b2d6bc-afe1-4696-9c37-f97a7ac416d7"
}

# default subscription is "Engineering Dev/Test"
variable "arm_subscription_id" {
  type        = string
  description = "Unique identifier of the Azure subscription used for billing."
  default     = "80b824de-ec53-4116-9868-3deeab10b0cd"
}

variable "arm_location" {
  type        = string
  description = "Name of the Azure location to create instances in."
  default     = "westus2"
}

variable "arm_resource_group_name" {
  type        = string
  description = "Name of the Azure resource group where tests will be run."
  default     = ""
}

variable "arm_department" {
  type        = string
  description = "Department that owns the resources should be one of: EngServ, Operations, Eng, Training, Solutions, Sales, BD, Success or Partner"
}

variable "arm_contact" {
  type        = string
  description = "The primary contact for the resources, this should be the IAM username and must be able to receive email by appending @chef.io to it (this person can explain what/why, might not be the business owner)."
}
