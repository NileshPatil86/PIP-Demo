output "github_actions_client_id" {
  description = "Set this as the AZURE_CLIENT_ID GitHub Actions variable/secret."
  value       = azuread_application.github_actions.client_id
}

output "azure_tenant_id" {
  description = "Set this as the AZURE_TENANT_ID GitHub Actions variable/secret."
  value       = var.tenant_id
}

output "azure_subscription_id" {
  description = "Set this as the AZURE_SUBSCRIPTION_ID GitHub Actions variable/secret."
  value       = var.subscription_id
}

output "tfstate_resource_group_name" {
  description = "Resource group holding the Terraform state storage account. Use in environments/prod/backend.hcl."
  value       = azurerm_resource_group.tfstate.name
}

output "tfstate_storage_account_name" {
  description = "Storage account holding Terraform state. Use in environments/prod/backend.hcl."
  value       = azurerm_storage_account.tfstate.name
}

output "tfstate_container_name" {
  description = "Blob container holding Terraform state files. Use in environments/prod/backend.hcl."
  value       = azurerm_storage_container.tfstate.name
}
