terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
      version = "2.7.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.44.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.7.2"
    }
    archive = {
      version = "~> 2.4"
      source  = "hashicorp/archive"
    }
    time = {
      source = "hashicorp/time"
      version = "0.13.1"
    }
  }
}