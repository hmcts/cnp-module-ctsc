locals {
  env_name = "ctscmail-${var.environment}"
}

# General RG

resource "azurerm_resource_group" "postfix-rg" {
  name     = "${local.env_name}-rg"
  location = "${var.location}"
}

# RG for mysql server and postfix share

resource "azurerm_resource_group" "data-rg" {
  name     = "${local.env_name}-data-rg"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "postfix_vnet" {
  name                = "${local.env_name}-vnet"
  address_space       = ["${data.azurerm_key_vault_secret.postfix_vnet_cidr.value}"]
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.postfix-rg.name}"
}

resource "azurerm_subnet" "postfix_data_subnet" {
  name                 = "${local.env_name}-data"
  resource_group_name  = "${azurerm_resource_group.postfix-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.postfix_vnet.name}"
  address_prefix       = "${data.azurerm_key_vault_secret.postfix_data_subnet.value}"
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet" "postfix_mgmt_subnet" {
  name                 = "${local.env_name}-mgmt"
  resource_group_name  = "${azurerm_resource_group.postfix-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.postfix_vnet.name}"
  address_prefix       = "${data.azurerm_key_vault_secret.postfix_mgmt_subnet.value}"
  # network_security_group_id   = "${azurerm_network_security_group.f5_mgmt_nsg.id}"
}

resource "azurerm_route_table" "route_postfix" {
  name                          = "${local.env_name}-udr"
  location                      = "${var.location}"
  resource_group_name           = "${azurerm_resource_group.postfix-rg.name}"
  disable_bgp_route_propagation = true
  tags                          = "${var.common_tags}"

  route {
    name                   = "to_hub_fw"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${module.palo_alto.ilb_private_ip_address}"
  }
}

resource "azurerm_subnet_route_table_association" "route_association" {
  subnet_id                                 = "${azurerm_subnet.postfix_data_subnet.id}"
  route_table_id                            = "${azurerm_route_table.route_postfix.id}"
}

# Storage accounts

# SA for ??? (nothing seems to be stored in these)

resource "azurerm_storage_account" "stor" {
  name = "${join("", list("ctsc2", substr(md5(azurerm_resource_group.postfix-rg.id), 0, 8)))}"
  location                 = "${var.location}"
  resource_group_name      = "${azurerm_resource_group.postfix-rg.name}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_replication_type}"
}

# SA for postfix share

resource "azurerm_storage_account" "data-stor" {
  name = "${join("", list("postfix2", substr(md5(azurerm_resource_group.postfix-rg.id), 0, 7)))}"
  location                 = "${var.location}"
  resource_group_name      = "${azurerm_resource_group.data-rg.name}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_replication_type}"
}

# Associated postfix share

resource "azurerm_storage_share" "postfix_share" {
  name                 = "postfix"
  resource_group_name  = "${azurerm_resource_group.data-rg.name}"
  storage_account_name = "${azurerm_storage_account.data-stor.name}"
  quota                = 20
}

resource "azurerm_availability_set" "avset" {
  name                         = "${local.env_name}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.postfix-rg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Azure LB stuff

resource "azurerm_lb" "lb" {
  resource_group_name = "${azurerm_resource_group.postfix-rg.name}"
  name                = "${local.env_name}"
  location            = "${var.location}"

  frontend_ip_configuration {
    name                          = "LoadBalancerFrontEnd"
    private_ip_address_allocation = "dynamic"
    subnet_id                     = "${azurerm_subnet.postfix_data_subnet.id}"
  }
}

resource "azurerm_lb_probe" "smtp_25_probe" {
  resource_group_name = "${azurerm_resource_group.postfix-rg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "SMTP-25-probe"
  port                = 25
  interval_in_seconds = 5
}

resource "azurerm_lb_rule" "smtp_25_rule" {
  resource_group_name            = "${azurerm_resource_group.postfix-rg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "SMTP-25-rule"
  protocol                       = "tcp"
  frontend_port                  = 25
  backend_port                   = 25
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  probe_id                       = "${azurerm_lb_probe.smtp_25_probe.id}"
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  resource_group_name = "${azurerm_resource_group.postfix-rg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "BackendPool1"
}

# Postfix VM-related stuff below

resource "azurerm_virtual_machine" "vm" {
  name                = "${local.env_name}${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.postfix-rg.name}"
  availability_set_id = "${azurerm_availability_set.avset.id}"
  vm_size             = "${var.postfix_vm_size}"
  primary_network_interface_id = "${element(azurerm_network_interface.postfix_trusted_nic.*.id, count.index)}"
  network_interface_ids = ["${element(azurerm_network_interface.postfix_trusted_nic.*.id, count.index)}", "${element(azurerm_network_interface.postfix_mgmt_nic.*.id, count.index)}"]
  count                         = 2
  delete_os_disk_on_termination = true

  plan {
    name      = "${var.image_sku}"
    publisher = "${var.image_publisher}"
    product   = "${var.image_offer}"
  }

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  storage_os_disk {
    name          = "${local.env_name}${count.index}"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${local.env_name}${count.index}"
    admin_username = "${data.azurerm_key_vault_secret.ssh_admin_user.value}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${data.azurerm_key_vault_secret.ssh_admin_user.value}/.ssh/authorized_keys"
      key_data = "${data.azurerm_key_vault_secret.ssh_public_key.value}" 
      #key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }
}

resource "azurerm_network_interface" "postfix_mgmt_nic" {
  name                = "${local.env_name}-mgmt-${count.index}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.postfix-rg.name}"
  count               = "${var.vm_count}"

  ip_configuration {
    name                          = "${join("", list("ipconfig", "1"))}"
    subnet_id                     = "${azurerm_subnet.postfix_mgmt_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_network_interface" "postfix_trusted_nic" {
  name                 = "${local.env_name}${count.index}"
  location             = "${var.resource_group_location}"
  resource_group_name  = "${azurerm_resource_group.postfix-rg.name}"
  count                = "${var.vm_count}"
  enable_ip_forwarding = true
  ip_configuration {
    name                                    = "${join("", list("ipconfig", "0"))}"
    subnet_id                               = "${azurerm_subnet.postfix_data_subnet.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.backend_pool.id}"]
  }
}

# Mysql-related stuff below

resource "azurerm_mysql_server" "db" {
  name                = "${local.env_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.data-rg.name}"

  sku {
    name     = "B_Gen5_1"
    capacity = 1
    tier     = "Basic"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "${data.azurerm_key_vault_secret.mysql_admin_user.value}"
  administrator_login_password = "${data.azurerm_key_vault_secret.mysql_admin_password.value}"
  version                      = "5.7"
  ssl_enforcement              = "Disabled"
}

resource "azurerm_mysql_firewall_rule" "db_fw_rule" {
  name                = "Allow_${local.env_name}${count.index}"
  server_name         = "${azurerm_mysql_server.db.name}"
  resource_group_name = "${azurerm_resource_group.data-rg.name}"
  start_ip_address = "${element(azurerm_network_interface.postfix_mgmt_nic.*.private_ip_address, count.index)}"
  end_ip_address = "${element(azurerm_network_interface.postfix_mgmt_nic.*.private_ip_address, count.index)}"
}

resource "azurerm_mysql_firewall_rule" "db_fw_azure_rule" {
  name                = "AllowAllWindowsAzureIps"
  server_name         = "${azurerm_mysql_server.db.name}"
  resource_group_name = "${azurerm_resource_group.data-rg.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_mysql_database" "postfix" {
  name                = "mailserver"
  resource_group_name = "${azurerm_resource_group.data-rg.name}"
  server_name         = "${azurerm_mysql_server.db.name}"
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

#resource "azurerm_storage_container" "db" {
  #name                 = "db-dumps"
  #resource_group_name  = "${azurerm_resource_group.data-rg.name}"
  #storage_account_name = "${azurerm_storage_account.data-stor.name}"
#}

