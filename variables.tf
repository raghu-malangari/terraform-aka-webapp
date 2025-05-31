variable "rgname" {
  type        = string
  description = "resource group name"
  default = "odevorg"

}

variable "location" {
  type    = string
  default = "swedencentral"
}

variable "service_principal_name" {
  type = string
  default = "odevosp"
}

variable "keyvault_name" {
  type = string
  default = "odevovault"
}

variable "SUB_ID" {
  type = string
  default = "odevosubid"
}
