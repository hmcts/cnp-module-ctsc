terraform {
  # backend "azurerm" {}

    backend "local" {
    path = "terraform.tfstate"
  }
}

