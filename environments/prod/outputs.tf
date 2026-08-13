output "cluster_name" {
  value = module.aks.cluster_name
}

output "resource_group_name" {
  value = module.aks.resource_group_name
}

output "node_resource_group" {
  value = module.aks.node_resource_group
}

output "oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

output "kube_admin_credentials_command" {
  value = module.aks.kube_admin_credentials_command
}

output "acr_login_server" {
  value = module.aks.acr_login_server
}

output "key_vault_uri" {
  value = module.aks.key_vault_uri
}

output "log_analytics_workspace_id" {
  value = module.aks.log_analytics_workspace_id
}
