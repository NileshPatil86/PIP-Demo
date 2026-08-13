terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  # Intentionally local backend: this stack creates the remote backend used
  # by everything else, so it cannot depend on that backend existing yet.
  # See README.md for how to protect/migrate this state after first apply.
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }

  subscription_id     = var.subscription_id
  tenant_id           = var.tenant_id
  storage_use_azuread = true
}

provider "azuread" {
  tenant_id = var.tenant_id
}
