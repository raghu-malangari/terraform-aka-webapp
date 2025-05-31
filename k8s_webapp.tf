# ConfigMap holding the custom index.html content to be served by nginx
resource "kubernetes_config_map" "nginx_index" {
  metadata {
    name = "nginx-index"
  }

  data = {
    "index.html" = <<-EOF
      <!DOCTYPE html>
      <html>
      <head><title>Welcome</title></head>
      <body><h1>Hello Raghu Malangari</h1></body>
      </html>
    EOF
  }
}

# Deployment resource for the webapp nginx pod(s)
resource "kubernetes_deployment" "webapp" {
  metadata {
    name = "webapp"
    labels = {
      app = "webapp"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "webapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "webapp"
        }
      }

      spec {
        security_context {
       #   run_as_non_root = true
       #   run_as_user     = 1000
        }

        container {
          image = "nginx:latest"
          name  = "webapp"

          port {
            container_port = 80
          }

          volume_mount {
            name       = "index-html"
            mount_path = "/usr/share/nginx/html/index.html"
            sub_path   = "index.html"
            read_only  = true
          }

          # Mount the writable cache volume for non-root NGINX
          volume_mount {
            name       = "nginx-cache"
            mount_path = "/var/cache/nginx"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }

          resources {
            limits = {
              cpu    = "300m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }

        volume {
          name = "index-html"
          config_map {
            name = "nginx-index"
          }
        }

        # Volume definition for NGINX cache directory
        volume {
          name      = "nginx-cache"
          empty_dir {}
        }
      }
    }
  }
}

# Service to expose the deployment externally via LoadBalancer
resource "kubernetes_service" "webapp_service" {
  metadata {
    name = "webapp-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.webapp.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}

resource "azurerm_public_ip" "webapp_ip" {
  name                = "webapp-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  # Assign DNS name here (subdomain)
  domain_name_label = "webapp-${random_string.suffix.result}" # FQDN will be webapp-xxxxx.region.cloudapp.azure.com
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

