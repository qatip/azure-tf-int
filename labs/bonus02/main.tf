resource "azurerm_resource_group" "rg" {
  name     = "RG1"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "lab10-aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "lab10-aks"
  node_resource_group = "RG2"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
    upgrade_settings {
      max_surge                     = "10%" 
      drain_timeout_in_minutes      = 0     
      node_soak_duration_in_minutes = 0     
    }
  }
  identity {
    type = "SystemAssigned"
  }
}
