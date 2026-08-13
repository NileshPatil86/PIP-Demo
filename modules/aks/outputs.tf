output "resource_group_name" {
  description = "Resource group containing all AKS-related resources."
  value       = local.resource_group_name
}

output "cluster_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "node_resource_group" {
  description = "Auto-managed resource group holding AKS-managed infrastructure (VMSS, LB, disks)."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL, used to federate workload identities for pods."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kube_admin_credentials_command" {
  description = "Command to fetch kubeconfig using your Azure AD identity (requires azure_rbac_enabled + membership in aad_admin_group_object_ids)."
  value       = "az aks get-credentials --resource-group ${local.resource_group_name} --name ${azurerm_kubernetes_cluster.this.name} --overwrite-existing"
}

output "control_plane_identity_id" {
  description = "User-assigned managed identity ID used by the AKS control plane."
  value       = azurerm_user_assigned_identity.aks.id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the kubelet identity - useful for federating workload identity or granting resource access."
  value       = azurerm_user_assigned_identity.kubelet.client_id
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry linked to this cluster."
  value       = azurerm_container_registry.this.login_server
}

output "acr_id" {
  description = "Resource ID of the Azure Container Registry."
  value       = azurerm_container_registry.this.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault available to workloads via the CSI Secrets Store provider."
  value       = azurerm_key_vault.this.vault_uri
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID receiving AKS diagnostics and Container Insights."
  value       = azurerm_log_analytics_workspace.this.id
}

output "vnet_id" {
  description = "Virtual network ID hosting the AKS subnet."
  value       = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  description = "Subnet ID used by the AKS node pools."
  value       = azurerm_subnet.aks.id
}
