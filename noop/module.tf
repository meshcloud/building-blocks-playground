variable "num" {
  type = number
  default = 0
}

variable "text" {
  type = string
  default = "foo"
}

variable "flag" {
  type = bool
  default = false
}

output "num" {
  value = var.num
}

output "text" {
  value = var.text
}

output "flag" {
  value = var.flag
}

resource "azurerm_private_endpoint" "pep" {
  count               = var.enable_private_endpoint == true ? 1 : 0
  name                = "pep-${azurerm_storage_account.storage_account.name}-blob"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  subnet_id           = var.subnet_id_private_endpoint
  tags                = local.mandatory_tags

  custom_network_interface_name = "pep-${azurerm_storage_account.storage_account.name}-blob"

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.storage_account.name}-blob"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  # Benötigt zentrale "privatelink.blob.core.windows.net" DNS Zone im Hub
  private_dns_zone_group {
    name                 = "dns-${azurerm_storage_account.storage_account.name}-blob"
    private_dns_zone_ids = data.azurerm_private_dns_zone.dns-blob.*.id
  }
}
