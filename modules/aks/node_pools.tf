resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_pool_vm_size
  vnet_subnet_id        = azurerm_subnet.aks.id
  zones                 = var.availability_zones
  mode                  = "User"
  os_disk_size_gb       = var.user_node_pool_os_disk_size_gb

  auto_scaling_enabled = true
  min_count            = var.user_node_pool_min_count
  max_count            = var.user_node_pool_max_count

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags
}
