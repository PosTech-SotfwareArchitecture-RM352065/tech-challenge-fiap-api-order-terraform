terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.1"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  backend "azurerm" {
    key = "terraform-order.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "github" {
}

provider "random" {
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "resource_group" {
  name       = "fiap-tech-challenge-order-group"
  location   = "eastus"
  managed_by = "fiap-tech-challenge-main-group"

  tags = {
    environment = "development"
  }
}

resource "random_password" "sqlserver_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_uuid" "sqlserver_user" {
}

provider "github" {
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "sanduba-order-sqlserver"
  resource_group_name          = azurerm_resource_group.resource_group.name
  location                     = azurerm_resource_group.resource_group.location
  version                      = "12.0"
  administrator_login          = random_uuid.sqlserver_user.result
  administrator_login_password = random_password.sqlserver_password.result

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

resource "azurerm_sql_active_directory_administrator" "entra_access_sqlserver" {
  server_name         = azurerm_sql_server.sqlserver.name
  resource_group_name = azurerm_resource_group.resource_group.name
  login               = "sqladmin"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
}

resource "azurerm_mssql_firewall_rule" "sqlserver_allow_azure_services_rule" {
  name             = "Allow access to Azure services"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "sanduba_order_database" {
  name                 = "sanduba-order-database"
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

resource "github_actions_organization_secret" "order_database_connectionstring" {
  secret_name     = "APP_ORDER_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sanduba_order_database.name};Persist Security Info=False;User ID=${random_uuid.sqlserver_user.result};Password=${random_password.sqlserver_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}