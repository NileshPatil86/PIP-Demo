data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.name_prefix}-aks-control-plane"
  location            = var.location
  resource_group_name = local.resource_group_name
  tags                = var.tags
}

# Control-plane identity needs rights on the VNet it doesn't own, to manage
# the load balancer / NSG rules AKS creates for Services of type LoadBalancer.
resource "azurerm_role_assignment" "aks_network" {
  scope                = azurerm_virtual_network.this.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Explicit, Terraform-managed kubelet identity (used by nodes to pull images, etc.)
# instead of letting AKS auto-generate an untracked one.
resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "id-${var.name_prefix}-aks-kubelet"
  location            = var.location
  resource_group_name = local.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "control_plane_kubelet_operator" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}
