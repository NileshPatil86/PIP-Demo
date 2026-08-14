variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD (Entra ID) tenant ID."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "centralindia"
}

variable "name_prefix" {
  description = "Short prefix used to derive resource names."
  type        = string
  default     = "pipdemo-prod"
}

variable "resource_group_name" {
  description = "Resource group name for the AKS environment."
  type        = string
  default     = "rg-pip-demo-prod"
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    project     = "PIP-Demo"
    environment = "prod"
    managed_by  = "terraform"
  }
}

variable "vnet_address_space" {
  description = "Address space for the AKS virtual network."
  type        = list(string)
  default     = ["10.60.0.0/16"]
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes for the AKS subnet."
  type        = list(string)
  default     = ["10.60.0.0/20"]
}

variable "aad_admin_group_object_ids" {
  description = "Azure AD group object IDs granted cluster-admin via Azure RBAC for Kubernetes Authorization."
  type        = list(string)
  default     = []
}

variable "api_server_authorized_ip_ranges" {
  description = "Public CIDR ranges allowed to reach the AKS API server (office egress, VPN, self-hosted runner, etc.). Empty list = no IP restriction (API server open to the internet, relying on Azure AD RBAC only). POC-only default; set real ranges before treating this as production."
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "Kubernetes version. Leave null to use AKS's current default at creation time."
  type        = string
  default     = null
}

variable "system_node_pool_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "system_node_pool_min_count" {
  type    = number
  default = 3
}

variable "system_node_pool_max_count" {
  type    = number
  default = 5
}

variable "user_node_pool_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "user_node_pool_min_count" {
  type    = number
  default = 3
}

variable "user_node_pool_max_count" {
  type    = number
  default = 10
}

variable "acr_sku" {
  type    = string
  default = "Premium"
}

variable "log_analytics_retention_days" {
  type    = number
  default = 90
}
