module "aks" {
  source = "../../modules/aks"

  name_prefix           = var.name_prefix
  location              = var.location
  resource_group_name   = var.resource_group_name
  create_resource_group = true
  tags                  = var.tags

  vnet_address_space          = var.vnet_address_space
  aks_subnet_address_prefixes = var.aks_subnet_address_prefixes

  aad_admin_group_object_ids      = var.aad_admin_group_object_ids
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  kubernetes_version = var.kubernetes_version

  system_node_pool_vm_size   = var.system_node_pool_vm_size
  system_node_pool_min_count = var.system_node_pool_min_count
  system_node_pool_max_count = var.system_node_pool_max_count

  user_node_pool_vm_size   = var.user_node_pool_vm_size
  user_node_pool_min_count = var.user_node_pool_min_count
  user_node_pool_max_count = var.user_node_pool_max_count

  acr_sku                      = var.acr_sku
  log_analytics_retention_days = var.log_analytics_retention_days
}
