variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    vm_size             = string
    os_type             = string
    os_disk_size_gb     = number
    node_count          = number
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
    max_pods            = number
    vnet_subnet_id      = string
    zones               = list(string)
    mode                = string
    node_labels         = map(string)
    tags                = map(string)
  }))
  default = {
    "appnodepool" = {
      vm_size             = "Standard_B2s"
      os_type             = "Linux"
      os_disk_size_gb     = 30
      node_count          = 1
      min_count           = 1
      max_count           = 1
      enable_auto_scaling = true
      max_pods            = 30
      vnet_subnet_id      = ""
      zones               = ["1"]
      mode                = "User"
      node_labels         = {
        "role" = "app"
      }
      tags = {
        "env" = "prod"
      }
    }
  }
}
variable "kubernetes_version" {
  description = "Kubernetes version to use for the node pools"
  type        = string
  default     = "1.31.1"
}
