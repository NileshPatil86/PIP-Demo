resource "azurerm_container_registry" "this" {
  name                          = "acr${local.compact_name}"
  location                      = var.location
  resource_group_name           = local.resource_group_name
  sku                           = var.acr_sku
  admin_enabled                 = false
  public_network_access_enabled = true

  # Premium SKU required for both zone redundancy and network rule/service-endpoint restrictions.
  zone_redundancy_enabled = var.acr_sku == "Premium" ? true : false

  tags = var.tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}
