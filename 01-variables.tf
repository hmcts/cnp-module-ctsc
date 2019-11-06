locals {
  trusted_vnet_resource_group   = "core-infra-${var.environment}"
  trusted_vnet_name             = "core-infra-vnet-${var.environment}"
  untrusted_vnet_resource_group = "core-infra-${var.environment}"
  untrusted_vnet_name           = "core-infra-vnet-${var.environment}"
}

variable "common_tags" {
  default = {
    "Team Name" = "CTSC"
  }
}

variable "trusted_destination_ip" {
  default = ""
}

variable "trusted_destination_host" {
  default = ""
}

variable "trusted_vnet_subnet_name" {
  description = "Name of the trusted vnet subnet."
  default     = "palo-trusted"
}

variable "untrusted_vnet_subnet_name" {
  description = "Name of the untrusted vnet subnet."
  default     = "palo-untrusted"
}

variable "cluster_size" {
  default = "2"
}

variable "resource_group_location" {
  default = "UK South"
}

variable "palo_vm_size" {
  description = "Specifies the size of Palo virtual machine."
  default     = "Standard_D3_v2"
}

variable "postfix_vm_size" {
  description = "Specifies the size of the Postfix virtual machine."
  default     = "Standard_D1_v2"
}

variable "vm_offer" {
  default = "vmseries1"
}

variable "allowed_external_ip" {
  type    = "string"
  default = "0.0.0.0/0"
}

variable "marketplace_sku" {
  default = "bundle2"
}

variable "marketplace_offer" {
  default = "vmseries1"
}

variable "marketplace_publisher" {
  default = "paloaltonetworks"
}

variable "pip_ansible_version" {
  default = "2.6.4"
}

variable "pip_netaddr_version" {
  default = "0.7.19"
}

variable "environment" {
  description = "The name of the environment in which to deploy the infrastructure."
}

variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "uksouth"
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.0.10.0/24"
}

variable "storage_account_tier" {
  description = "Defines the Tier of storage account to be created. Valid options are Standard and Premium."
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Defines the Replication Type to use for this storage account. Valid options include LRS, GRS etc."
  default     = "LRS"
}

variable "image_publisher" {
  description = "name of the publisher of the image (az vm image list)"
  default     = "center-for-internet-security-inc"
}

variable "image_offer" {
  description = "the name of the offer (az vm image list)"
  default     = "cis-ubuntu-linux-1804-l1"
}

variable "image_sku" {
  description = "image sku to apply (az vm image list)"
  default     = "cis-ubuntu1804-l1"
}

variable "image_version" {
  description = "version of the image to apply (az vm image list)"
  default     = "1.0.7"
}

variable "loadbalancer_username" {
  description = "Username to provision the VM with"
  default     = ""
}

variable "loadbalancer_password" {
  description = "Password to provision the VM with"
  default     = ""
}

variable "loadbalancer_data_subnet" {
  description = "Data subnet of the F5"
  default     = ""
}

variable "vm_count" {
  description = "Number of postfix VMs"
  default     = "2"
}

variable "subscription" {
  description = "Subscription value for infra-vault"
}

variable "sub_full_name" {
}

variable "product" {
  description = "Product name to be passed through to palo module"
  default = "ctsc-email"
}

variable "pan_resource_group" {
  default = ""
}

variable "pfx_certificate_name" {

}
