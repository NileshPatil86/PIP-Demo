variable "name_prefix" {
  description = "Short prefix used to derive resource names (e.g. \"pipdemo-prod\")."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "create_resource_group" {
  description = "Whether this module should create its own resource group. Set false to deploy into an existing one via resource_group_name."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Resource group name. Created if create_resource_group is true, otherwise must already exist."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space for the AKS virtual network."
  type        = list(string)
  default     = ["10.60.0.0/16"]
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes for the subnet hosting AKS nodes/pods."
  type        = list(string)
  default     = ["10.60.0.0/20"]
}

# ---------------------------------------------------------------------------
# Cluster identity / access
# ---------------------------------------------------------------------------

variable "aad_admin_group_object_ids" {
  description = "Azure AD (Entra ID) group object IDs granted cluster-admin via Azure RBAC for Kubernetes Authorization."
  type        = list(string)
  default     = []
}

variable "api_server_authorized_ip_ranges" {
  description = "Public CIDR ranges allowed to reach the AKS API server (e.g. office egress IPs, GitHub Actions runner IP ranges/self-hosted runner IP). Required for a public cluster locked down to trusted sources."
  type        = list(string)
}

# ---------------------------------------------------------------------------
# Kubernetes cluster
# ---------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version for the control plane and default node pool. Leave null to use AKS's current default."
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "AKS control plane SKU tier. \"Standard\" enables the financially-backed Uptime SLA, recommended for production."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be one of Free, Standard, Premium."
  }
}

variable "automatic_upgrade_channel" {
  description = "AKS automatic upgrade channel."
  type        = string
  default     = "stable"
}

variable "node_os_upgrade_channel" {
  description = "Node OS auto-upgrade channel."
  type        = string
  default     = "NodeImage"
}

variable "network_policy" {
  description = "Network policy engine for the cluster (\"azure\" or \"calico\")."
  type        = string
  default     = "azure"
}

# ---------------------------------------------------------------------------
# System node pool
# ---------------------------------------------------------------------------

variable "system_node_pool_vm_size" {
  description = "VM SKU for the system node pool."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "system_node_pool_min_count" {
  description = "Minimum node count for the system node pool autoscaler."
  type        = number
  default     = 3
}

variable "system_node_pool_max_count" {
  description = "Maximum node count for the system node pool autoscaler."
  type        = number
  default     = 5
}

variable "system_node_pool_os_disk_size_gb" {
  description = "OS disk size (GB) for system node pool nodes."
  type        = number
  default     = 128
}

variable "availability_zones" {
  description = "Availability zones used by node pools."
  type        = list(string)
  default     = ["1", "2", "3"]
}

# ---------------------------------------------------------------------------
# User (workload) node pool
# ---------------------------------------------------------------------------

variable "user_node_pool_vm_size" {
  description = "VM SKU for the general-purpose user node pool."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "user_node_pool_min_count" {
  description = "Minimum node count for the user node pool autoscaler."
  type        = number
  default     = 3
}

variable "user_node_pool_max_count" {
  description = "Maximum node count for the user node pool autoscaler."
  type        = number
  default     = 10
}

variable "user_node_pool_os_disk_size_gb" {
  description = "OS disk size (GB) for user node pool nodes."
  type        = number
  default     = 128
}

# ---------------------------------------------------------------------------
# ACR
# ---------------------------------------------------------------------------

variable "acr_sku" {
  description = "Azure Container Registry SKU."
  type        = string
  default     = "Premium"
}

# ---------------------------------------------------------------------------
# Log Analytics / monitoring
# ---------------------------------------------------------------------------

variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention in days."
  type        = number
  default     = 90
}

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

variable "key_vault_soft_delete_retention_days" {
  description = "Key Vault soft-delete retention in days."
  type        = number
  default     = 90
}
