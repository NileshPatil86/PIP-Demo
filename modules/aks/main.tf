resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.name_prefix}"
  location            = var.location
  resource_group_name = local.resource_group_name
  dns_prefix          = "aks-${var.name_prefix}"

  kubernetes_version        = var.kubernetes_version
  sku_tier                  = var.sku_tier
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Force Azure AD authentication - no local Kubernetes admin accounts.
  local_account_disabled = true

  automatic_upgrade_channel = var.automatic_upgrade_channel
  node_os_upgrade_channel   = var.node_os_upgrade_channel

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool_vm_size
    vnet_subnet_id               = azurerm_subnet.aks.id
    zones                        = var.availability_zones
    os_disk_size_gb              = var.system_node_pool_os_disk_size_gb
    only_critical_addons_enabled = true

    auto_scaling_enabled = true
    min_count            = var.system_node_pool_min_count
    max_count            = var.system_node_pool_max_count

    upgrade_settings {
      max_surge = "33%"
    }

    tags = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  kubelet_identity {
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled     = true
    admin_group_object_ids = var.aad_admin_group_object_ids
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = var.network_policy
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  azure_policy_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    duration    = 4
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version, # allow in-place upgrades outside Terraform without perpetual diffs
    ]
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.aks_network,
    azurerm_role_assignment.control_plane_kubelet_operator,
  ]
}
