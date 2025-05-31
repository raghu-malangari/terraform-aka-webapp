# Output block to expose raw kubeconfig as output
output "config" {
  value = azurerm_kubernetes_cluster.aks-cluster.kube_config_raw  # Return the raw kubeconfig for CLI or scripting use
}
