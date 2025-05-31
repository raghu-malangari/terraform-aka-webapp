# Create an Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "aks-rg"                  # Name of the resource group
  location = "swedencentral"          # Azure region to deploy resources into
}

# Create the Azure Kubernetes Service (AKS) cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"                       # Name of the AKS cluster
  location            = azurerm_resource_group.rg.location  # Region from the resource group
  resource_group_name = azurerm_resource_group.rg.name      # Resource group for the cluster
  dns_prefix          = "aks-cluster"                       # DNS prefix for the AKS API server

  # Define the default node pool (mandatory)
  default_node_pool {
    name                  = "defaultpool"                   # Name of the node pool
    vm_size               = "Standard_D2s_v3"               # Size/type of virtual machines
    zones                 = [1, 2, 3]                        # Availability zones for resiliency
    auto_scaling_enabled  = true                            # Enable autoscaling of nodes
    max_count             = 1                               # Maximum number of nodes
    min_count             = 1                               # Minimum number of nodes
    os_disk_size_gb       = 30                              # Size of OS disk in GB
    type                  = "VirtualMachineScaleSets"       # Node pool managed by VMSS
  }

  identity {
    type = "SystemAssigned"                                 # Use a system-assigned managed identity
  }

  # Define the Linux profile for admin access
  linux_profile {
    admin_username = "azureuser"                            # Admin username for node access

    ssh_key {
      key_data = file("~/.ssh/id_rsa.pub")                  # SSH public key for secure access
    }
  }

  # Define the network settings for the AKS cluster
  network_profile {
    network_plugin    = "azure"                             # Use Azure CNI for networking
    load_balancer_sku = "standard"                          # Use standard SKU for the load balancer
  }
}

# Create additional node pools for different products using a map variable
resource "azurerm_kubernetes_cluster_node_pool" "product_nodepool" {
  for_each              = var.node_pools                    # Iterate over the node_pools map

  name                  = each.key                          # Name of the node pool
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id # Link to the main AKS cluster
  vm_size               = each.value.vm_size                # VM size for the pool
  os_type               = each.value.os_type                # OS type (Linux/Windows)
  os_disk_size_gb       = each.value.os_disk_size_gb        # OS disk size in GB
  node_count            = each.value.node_count             # Initial number of nodes
  auto_scaling_enabled  = true                              # Always enable autoscaling
  min_count             = each.value.min_count              # Minimum number of nodes
  max_count             = each.value.max_count              # Maximum number of nodes
  max_pods              = each.value.max_pods               # Maximum number of pods per node
  zones                 = each.value.zones                  # Availability zones
  mode                  = each.value.mode                   # Node pool mode (System/User)

  node_labels           = each.value.node_labels            # Custom labels for nodes
  tags                  = each.value.tags                   # Resource tags for the node pool

  orchestrator_version  = var.kubernetes_version            # Kubernetes version for the node pool

  depends_on = [azurerm_kubernetes_cluster.aks]             # Ensure the cluster is created before node pools
}

