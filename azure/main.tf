terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "fiap-tech-challenge-main-group"
    storage_account_name = "sandubaterraform"
    container_name       = "sanduba-terraform-storage-container"
    key = "terraform-database.tfstate"
  }
}

provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "resource_group" {
  name       = "fiap-tech-challenge-database-group"
  location   = "eastus"
  managed_by = "fiap-tech-challenge-main-group"

  tags = {
    environment = "development"
  }
}

# NOTE: the Name used for Redis needs to be globally unique
resource "azurerm_redis_cache" "sanduba_carrinho_database" {
  name                          = "sanduba-carrinho-database-redis"
  location                      = azurerm_resource_group.resource_group.location
  resource_group_name           = azurerm_resource_group.resource_group.name
  capacity                      = 0
  family                        = "C"
  sku_name                      = "Basic"
  enable_non_ssl_port           = false
  public_network_access_enabled = true
  redis_version                 = 6

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "sanduba-main-database-sqlserver"
  resource_group_name          = azurerm_resource_group.resource_group.name
  location                     = azurerm_resource_group.resource_group.location
  version                      = "12.0"
  administrator_login          = var.mssqlserver_adm_login
  administrator_login_password = var.mssqlserver_adm_password

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

resource "azurerm_mssql_database" "sanduba_main_database" {
  name                 = "sanduba-main-database"
  server_id            = azurerm_mssql_server.sqlserver.id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  sku_name             = "Basic"
  max_size_gb          = 2
  read_scale           = false
  zone_redundant       = false
  geo_backup_enabled   = false
  create_mode          = "Default"
  storage_account_type = "Local"

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}