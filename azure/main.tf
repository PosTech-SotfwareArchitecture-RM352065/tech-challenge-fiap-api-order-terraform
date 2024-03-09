terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  backend "azurerm" {
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

provider "github" {
}

# NOTE: the Name used for Redis needs to be globally unique
resource "azurerm_redis_cache" "sanduba_cart_database" {
  name                          = "sanduba-cart-database-redis"
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
  name                         = "sanduba-main-sqlserver"
  resource_group_name          = azurerm_resource_group.resource_group.name
  location                     = azurerm_resource_group.resource_group.location
  version                      = "12.0"
  administrator_login          = var.main_sqlserver_adm_login
  administrator_login_password = var.main_sqlserver_adm_password

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

resource "github_actions_organization_secret" "fiap_main_database_connectionstring" {
  secret_name     = "MAIN_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sanduba_main_database.name};Persist Security Info=False;User ID=${var.main_sqlserver_adm_login};Password=${var.main_sqlserver_adm_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

resource "github_actions_organization_secret" "fiap_cart_database_connectionstring" {
  secret_name     = "CART_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = azurerm_redis_cache.sanduba_cart_database.primary_connection_string
}