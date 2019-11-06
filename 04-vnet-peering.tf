resource "azurerm_virtual_network_peering" "ctscmail-2-hub" {
  name                      = "ctscemail-to-hub"
  resource_group_name       = "${azurerm_resource_group.postfix-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.postfix_vnet.name}"
  remote_virtual_network_id = "${data.azurerm_virtual_network.hub_vnet.id}"

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub-2-ctscmail" {
  name                      = "hub-to-ctscemail"
  resource_group_name       = "${data.azurerm_virtual_network.hub_vnet.resource_group_name}"
  virtual_network_name      = "${data.azurerm_virtual_network.hub_vnet.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.postfix_vnet.id}"

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}