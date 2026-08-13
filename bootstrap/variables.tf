variable "subscription_id" {
  description = "Azure subscription ID that will hold the Terraform state storage and the AKS workload resources."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD (Entra ID) tenant ID."
  type        = string
}

variable "location" {
  description = "Azure region for the state storage resource group."
  type        = string
  default     = "centralindia"
}

variable "state_resource_group_name" {
  description = "Name of the resource group that holds the Terraform remote state storage account."
  type        = string
  default     = "rg-pip-demo-tfstate"
}

variable "state_storage_account_name" {
  description = "Globally unique name for the Terraform state storage account (3-24 lowercase alphanumeric characters)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.state_storage_account_name))
    error_message = "state_storage_account_name must be 3-24 lowercase letters/numbers only (Azure storage account naming rules)."
  }
}

variable "state_container_name" {
  description = "Blob container name used to store Terraform state files."
  type        = string
  default     = "tfstate"
}

variable "github_org" {
  description = "GitHub organization or username that owns the repository (used to scope the OIDC federated credential trust)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (used to scope the OIDC federated credential trust)."
  type        = string
}

variable "github_environment" {
  description = "GitHub Environment name protecting the apply job (must match the `environment:` used in terraform-apply.yml)."
  type        = string
  default     = "production"
}

variable "workload_role_definition" {
  description = "Azure RBAC role granted to the GitHub Actions identity at subscription scope so it can provision AKS/networking/ACR/etc. Scope this down to a resource-group in real production use."
  type        = string
  default     = "Contributor"
}

variable "tags" {
  description = "Common tags applied to all bootstrap resources."
  type        = map(string)
  default = {
    project    = "PIP-Demo"
    managed_by = "terraform"
    purpose    = "tfstate-and-oidc-bootstrap"
  }
}
