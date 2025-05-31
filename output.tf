output "aks_cluster_name" {
  description = "The name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "node_pools" {
  description = "The created node pools."
  value       = azurerm_kubernetes_cluster_node_pool.product_nodepool
}

output "webapp_external_ip" {
  value = kubernetes_service.webapp_service.status[0].load_balancer[0].ingress[0].ip
}

output "webapp_fqdn" {
  value = azurerm_public_ip.webapp_ip.fqdn
  description = "Access your app using this DNS name"
}
