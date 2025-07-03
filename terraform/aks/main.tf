module "naming" {
  source  = "Azure/naming/azurerm"
  suffix  = ["su", "fix"]
  version = "0.4.2"
}

# resource "random_id" "prefix" {
#   byte_length = 8
# }

resource "random_id" "name" {
  byte_length = 8
}

resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0

  location = var.location
  name     = coalesce(var.resource_group_name, module.naming.resource_group.name)
}

locals {
  resource_group = {
    name     = var.create_resource_group ? azurerm_resource_group.main[0].name : var.resource_group_name
    location = var.location
  }
}

resource "azurerm_virtual_network" "this" {
  address_space       = ["10.52.0.0/16"]
  location            = local.resource_group.location
  name                = module.naming.virtual_network.name
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet" "this" {
  address_prefixes     = ["10.52.0.0/24"]
  name                 = module.naming.subnet.name
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.this.name
}

module "aks" {
  source  = "Azure/aks/azurerm//v4"
  version = "10.1.1"

  rbac_aad_tenant_id        = data.azurerm_client_config.current.tenant_id
  location                  = local.resource_group.location
  prefix                    = random_id.name.hex
  resource_group_name       = local.resource_group.name
  kubernetes_version        = "1.29" # don't specify the patch version!
  automatic_channel_upgrade = "patch"
  agents_availability_zones = ["1", "2"]
  agents_count              = null
  agents_max_count          = 2
  agents_max_pods           = 100
  agents_min_count          = 1
  agents_pool_name          = "testnodepool"
  agents_pool_linux_os_configs = [
    {
      transparent_huge_page_enabled = "always"
      sysctl_configs = [
        {
          fs_aio_max_nr               = 65536
          fs_file_max                 = 100000
          fs_inotify_max_user_watches = 1000000
        }
      ]
    }
  ]
  agents_type          = "VirtualMachineScaleSets"
  azure_policy_enabled = true
  # client_id            = var.client_id
  # client_secret        = var.client_secret
  # confidential_computing = {
  #   sgx_quote_helper_enabled = true
  # }
  disk_encryption_set_id = azurerm_disk_encryption_set.des.id
  enable_auto_scaling    = true
  enable_host_encryption = true
  green_field_application_gateway_for_ingress = {
    name        = module.naming.application_gateway.name
    subnet_cidr = "10.52.1.0/24"
  }
  local_account_disabled = false
  #checkov:skip=CKV_AZURE_4:The logging is turn off for demo purpose. DO NOT DO THIS IN PRODUCTION ENVIRONMENT!
  log_analytics_workspace_enabled      = false
  cluster_log_analytics_workspace_name = random_id.name.hex
  maintenance_window = {
    allowed = [
      {
        day   = "Sunday",
        hours = [22, 23]
      },
    ]

    not_allowed = [
      {
        start = "2035-01-01T20:00:00Z",
        end   = "2035-01-01T21:00:00Z"
      },
    ]
  }
  maintenance_window_node_os = {
    frequency  = "Daily"
    interval   = 1
    start_time = "07:00"
    utc_offset = "+01:00"
    duration   = 16
  }
  net_profile_dns_service_ip        = "10.0.0.10"
  net_profile_service_cidr          = "10.0.0.0/16"
  network_plugin                    = "azure"
  network_plugin_mode               = "overlay"
  network_policy                    = "calico"
  node_os_channel_upgrade           = "NodeImage"
  os_disk_size_gb                   = 60
  private_cluster_enabled           = true
  rbac_aad                          = true
  role_based_access_control_enabled = true
  sku_tier                          = "Standard"
  vnet_subnet = {
    id = azurerm_subnet.this.id
  }

  agents_labels = {
    "node1" : "label1"
  }
  agents_tags = {
    "Agent" : "agentTag"
  }
  depends_on = [
    azurerm_subnet.this,
  ]
}