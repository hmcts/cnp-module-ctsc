data "azurerm_key_vault" "infra_vault" {
  name                = "ctscemail-${var.environment}-mgmt"
  resource_group_name = "ctsc-email-mgmt-${var.environment}-rg"
}

data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "ssh-admin-public-key"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "ssh-admin-private-key"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "lb_ip_dns_name" {
  name         = "lb-ip-dns-name"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "dns_name" {
  name         = "dns-name"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "ssh_admin_user" {
  name         = "ssh-admin-user"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "ssh_admin_password" {
  name         = "ssh-admin-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "mysql_admin_user" {
  name         = "mysql-admin-user"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "mysql_admin_password" {
  name         = "mysql-admin-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "mysql_mailread_user" {
  name         = "mysql-read-user"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "mysql_mailread_password" {
  name         = "mysql-read-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "mysql_mailadmin_user" {
  name         = "mysql-mailadmin-user"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "mysql_mailadmin_password" {
  name         = "mysql-mailadmin-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "mail_user" {
  name         = "mail-user"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "mail_password" {
  name         = "mail-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "pfx_password" {
  name         = "pfx-certificate-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "loadbalancer_username" {
  name         = "loadbalancer-username"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "loadbalancer_password" {
  name         = "loadbalancer-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "as3_username" {
  name         = "as3-username"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "as3_password" {
  name         = "as3-password"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "f5_vnet_cidr" {
  name         = "f5-vnet-cidr"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "f5_data_subnet" {
  name         = "f5-data-subnet"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "f5_mgmt_subnet" {
  name         = "f5-mgmt-subnet"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "f5_nsg_mgmt_rules" {
  name         = "f5-nsg-mgmt-rules"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "postfix_vnet_cidr" {
  name         = "postfix-vnet-cidr"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "postfix_data_subnet" {
  name         = "postfix-data-subnet"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

data "azurerm_key_vault_secret" "postfix_mgmt_subnet" {
  name         = "postfix-mgmt-subnet"
  key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
}

#data "azurerm_key_vault_secret" "hub_vnet_address_space" {
  #name         = "hub-vnet-address-space"
  #key_vault_id = "${data.azurerm_key_vault.infra_vault.id}"
#}

data "template_file" "inventory" {
  template = <<EOF
[postfix]
$${postfix0_ip} mail_host=$${mail_host0}
$${postfix1_ip} mail_host=$${mail_host1}

[all:vars]
ansible_ssh_private_key_file = $${key_path}
ansible_ssh_user = $${ssh_user}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
pfx_password = $${pfx_password}

[postfix:vars]
mysql_db = $${mysql_db}
mysql_host = $${mysql_host}
mysql_admin_user = $${mysql_admin_user}
mysql_admin_password = '$${mysql_admin_password}'
mysql_mailadmin_user = $${mysql_mailadmin_user}
mysql_mailadmin_password = '$${mysql_mailadmin_password}'
mysql_mailread_user = $${mysql_mailread_user}
mysql_mailread_password = '$${mysql_mailread_password}'
mail_user = $${mail_user}
mail_password = '$${mail_password}'
mail_domain = $${mail_domain}
postfix_storage_account_name = $${storage_account_name}
postfix_share_access_key = $${postfix_share_access_key}
environ = $${environ}
EOF


#   vars {
#     postfix0_ip = "${element(azurerm_network_interface.postfix_trusted_nic.*.private_ip_address, 0)}"
#     postfix1_ip = "${element(azurerm_network_interface.postfix_trusted_nic.*.private_ip_address, 1)}"
#     key_path                 = "~/.ssh/id_rsa"
#     mysql_host               = "${azurerm_mysql_server.db.fqdn}"
#     mysql_db                 = "${azurerm_mysql_database.postfix.name}"
#     mysql_admin_user         = "${data.azurerm_key_vault_secret.mysql_admin_user.value}"
#     mysql_admin_password     = "${data.azurerm_key_vault_secret.mysql_admin_password.value}"
#     mail_host0               = "${local.env_name}0.${data.azurerm_key_vault_secret.dns_name.value}"
#     mail_host1               = "${local.env_name}1.${data.azurerm_key_vault_secret.dns_name.value}"
#     mail_user                = "${data.azurerm_key_vault_secret.mail_user.value}"
#     mail_password            = "${data.azurerm_key_vault_secret.mail_password.value}"
#     mail_domain              = "${data.azurerm_key_vault_secret.dns_name.value}"
#     ssh_user                 = "${data.azurerm_key_vault_secret.ssh_admin_user.value}"
#     maildomain               = "${data.azurerm_key_vault_secret.dns_name.value}"
#     storage_account_name     = "${azurerm_storage_account.data-stor.name}"
#     postfix_share_access_key = "${azurerm_storage_account.data-stor.primary_access_key}"
#     mysql_mailadmin_user     = "${data.azurerm_key_vault_secret.mysql_mailadmin_user.value}"
#     mysql_mailadmin_password = "${data.azurerm_key_vault_secret.mysql_mailadmin_password.value}"
#     mysql_mailread_user      = "${data.azurerm_key_vault_secret.mysql_mailread_user.value}"
#     mysql_mailread_password  = "${data.azurerm_key_vault_secret.mysql_mailread_password.value}"
#     pfx_password             = "${data.azurerm_key_vault_secret.pfx_password.value}"
#     environ                  = "${var.environment}"
#   }
}

resource "null_resource" "update_inventory" {
  triggers = {
    always_run = "${timestamp()}"
  }

  #template = "${data.template_file.inventory.rendered}"

  provisioner "local-exec" {
    command = "echo \"${data.template_file.inventory.rendered}\" > /tmp/inventory"
  }
}