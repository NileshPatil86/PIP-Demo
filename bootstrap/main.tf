data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Remote state backend: Resource Group + Storage Account + Container
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "tfstate" {
  name     = var.state_resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                = var.state_storage_account_name
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = azurerm_resource_group.tfstate.location

  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  # No storage account keys: state access is via Azure AD (OIDC) identities only.
  shared_access_key_enabled       = false
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.state_container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# The bootstrap identity applying this stack needs data-plane rights to
# create the container above (data source auth uses Azure AD too).
resource "azurerm_role_assignment" "bootstrap_identity_storage" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC identity (Azure AD App Registration, no client secret)
# ---------------------------------------------------------------------------

resource "azuread_application" "github_actions" {
  display_name = "pip-demo-github-actions-oidc"
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
  owners    = [data.azurerm_client_config.current.object_id]
}

# Trust GitHub's OIDC token for pull requests hitting this repo (used by the plan workflow).
resource "azuread_application_federated_identity_credential" "pull_request" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-pull-request"
  description    = "Allows GitHub Actions to run `terraform plan` from pull requests via OIDC."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:pull_request"
}

# Trust GitHub's OIDC token for deployments to the protected `production` environment
# (used by the apply workflow, gated behind manual approval via GitHub Environments).
resource "azuread_application_federated_identity_credential" "environment" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-environment-${var.github_environment}"
  description    = "Allows GitHub Actions to run `terraform apply` for the ${var.github_environment} environment via OIDC."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:environment:${var.github_environment}"
}

# Trust pushes to main as well, in case apply is wired to run on push instead of / in addition to an Environment.
resource "azuread_application_federated_identity_credential" "main_branch" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-main-branch"
  description    = "Allows GitHub Actions to authenticate for pushes to main via OIDC."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
}

# ---------------------------------------------------------------------------
# RBAC for the GitHub Actions identity
# ---------------------------------------------------------------------------

# Provisions AKS, networking, ACR, Log Analytics, Key Vault, etc.
# NOTE: Contributor at subscription scope is broad. For real production,
# narrow this to the specific resource group(s) the workload uses.
resource "azurerm_role_assignment" "github_actions_workload" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = var.workload_role_definition
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Required so Terraform-managed resources (AKS -> ACR AcrPull, Key Vault Secrets
# Provider -> Key Vault Secrets User, etc.) can have role assignments created for them.
resource "azurerm_role_assignment" "github_actions_rbac_admin" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Data-plane access to the state storage account (use_azuread_auth backend, no access keys).
resource "azurerm_role_assignment" "github_actions_state_storage" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}
