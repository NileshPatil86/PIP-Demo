locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.this[0].name : var.resource_group_name

  # Storage/ACR/Key Vault names cannot contain hyphens - derive a compact alnum token.
  compact_name = replace(var.name_prefix, "/[^a-zA-Z0-9]/", "")
}
