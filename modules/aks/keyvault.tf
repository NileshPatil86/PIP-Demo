resource "azurerm_key_vault" "this" {
  name                = "kv-${substr(local.compact_name, 0, min(length(local.compact_name), 19))}"
  location            = var.location
  resource_group_name = local.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  public_network_access_enabled = true

  tags = var.tags
}

# Lets AKS's Key Vault Secrets Provider add-on (CSI driver) read secrets from this vault.
resource "azurerm_role_assignment" "aks_keyvault_secrets_provider" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
}
