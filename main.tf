# Configure an Azure Resource Group using input variables
resource "azurerm_resource_group" "rg1" {
  name     = var.rgname                         # Resource group name from variable
  location = var.location                      # Azure region from variable
}

# Module to create a Service Principal used for AKS authentication and Key Vault access
module "ServicePrincipal" {
  source                 = "./modules/ServicePrincipal"  # Path to the custom module
  service_principal_name = var.service_principal_name     # SP name passed as input
  depends_on = [
    azurerm_resource_group.rg1                          # Wait for RG to be created first
  ]
}

# Assign Contributor role to the Service Principal over the subscription scope
resource "azurerm_role_assignment" "rolespn" {
  scope                = "/subscriptions/550ea751-3a3c-4a25-8773-93d9ec783ca5"  # Full subscription scope
  role_definition_name = "Contributor"                                           # Assign Contributor access
  principal_id         = module.ServicePrincipal.service_principal_object_id     # SP Object ID from module
  depends_on = [
    module.ServicePrincipal                                 # Ensure SP is created first
  ]
}

# Module to provision an Azure Key Vault and grant access to the SP
module "keyvault" {
  source                      = "./modules/keyvault"              # Path to the Key Vault module
  keyvault_name               = var.keyvault_name                 # Key Vault name from variable
  location                    = var.location                      # Location from variable
  resource_group_name         = var.rgname                        # Use same RG
  service_principal_name      = var.service_principal_name        # SP name
  service_principal_object_id = module.ServicePrincipal.service_principal_object_id  # SP Object ID
  service_principal_tenant_id = module.ServicePrincipal.service_principal_tenant_id  # SP Tenant ID

  depends_on = [
    module.ServicePrincipal                                     # Ensure SP is created first
  ]
}

# Store the SP client secret as a secret in the Key Vault
resource "azurerm_key_vault_secret" "example" {
  name         = module.ServicePrincipal.client_id              # Use SP client ID as secret name
  value        = module.ServicePrincipal.client_secret          # Store the SP client secret
  key_vault_id = module.keyvault.keyvault_id                    # Target Key Vault from module

  depends_on = [
    module.keyvault                                           # Wait for Key Vault to be ready
  ]
}

# Module to create the Azure Kubernetes Service cluster
module "aks" {
  source                 = "./modules/aks/"                        # AKS module path
  service_principal_name = var.service_principal_name            # SP name
  client_id              = module.ServicePrincipal.client_id     # SP client ID
  client_secret          = module.ServicePrincipal.client_secret # SP client secret
  location               = var.location                          # Azure region
  resource_group_name    = var.rgname                            # RG to deploy AKS in

  depends_on = [
    module.ServicePrincipal                                     # Ensure SP exists first
  ]
}

# Output the AKS kubeconfig to a local file for access
resource "local_file" "kubeconfig" {
  depends_on = [module.aks]                      # Ensure AKS is ready
  filename   = "./kubeconfig"                   # Output file path
  content    = module.aks.config                 # Config output from AKS module
}
