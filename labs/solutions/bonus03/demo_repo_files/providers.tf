provider "azurerm" {
  features {}
  # The workflow passes this at plan/apply time
  subscription_id = var.subscription_id
}
