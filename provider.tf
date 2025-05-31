# This block defines the overall Terraform settings for required versions and providers
terraform {
  required_version = ">=1.0"  # Ensures Terraform version 1.0 or newer is used

  required_providers {
    azapi = {
      source  = "azure/azapi"            # Provider used to interact with new Azure APIs not yet in azurerm
      version = "~>1.5"                  # Use any version compatible with 1.5.x, but not 2.0 or later
    }
    azurerm = {
      source  = "hashicorp/azurerm"      # Main provider for managing Azure infrastructure
      version = "~> 4.12.0"                  # Use any version within the 4.x range
    }
    random = {
      source  = "hashicorp/random"       # Generates random values useful for unique resource naming
      version = "~> 3.0"                  # Use any version within the 3.x range
    }
    time = {
      source  = "hashicorp/time"         # Allows time-based operations (e.g., delays or timestamps)
      version = "0.9.1"                  # Pinned to a specific version to avoid incompatibility
    }
  }
}

# Configuration for the Azure Resource Manager (azurerm) provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false   # Prevents automatic permanent deletion of soft-deleted Key Vaults
    }
  }
  subscription_id = "550ea751-3a3c-4a25-8773-93d9ec783ca5"  # Azure subscription to deploy resources into
}

# Configuration for Azure Active Directory (azuread) provider
provider "azuread" {
  # This provider handles identities, roles, and groups in Azure Active Directory
  # Authentication is based on default Azure CLI credentials or environment variables
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

