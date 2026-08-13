terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    # Values are intentionally omitted here and supplied at `terraform init` time
    # via -backend-config=backend.hcl (local use) or -backend-config flags passed
    # by the GitHub Actions workflow, sourced from repository variables.
    # See backend.hcl for the non-secret values and README.md for the full flow.
  }
}
