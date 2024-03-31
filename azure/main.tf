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

resource "random_password" "mssql_user" {
  length  = 10
  lower   = true
  upper   = true
  special = false
}

resource "random_password" "mssql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
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
  administrator_login          = random_password.mssql_user.result
  administrator_login_password = random_password.mssql_password.result

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

resource "azurerm_mssql_firewall_rule" "sqlserver_allow_azure_services_rule" {
  name             = "Allow access to Azure services"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
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

resource "azurerm_cosmosdb_account" "sanduba_payment_database_account" {
  name                          = "sanduba-payment-database-account"
  location                      = azurerm_resource_group.resource_group.location
  resource_group_name           = azurerm_resource_group.resource_group.name
  offer_type                    = "Standard"
  enable_free_tier              = true
  kind                          = "MongoDB"
  public_network_access_enabled = true

  enable_automatic_failover = false

  mongo_server_version = 4.2

  consistency_policy {
    consistency_level = "BoundedStaleness"
  }

  geo_location {
    location          = azurerm_resource_group.resource_group.location
    failover_priority = 0
  }

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

resource "azurerm_cosmosdb_mongo_database" "sanduba_payment_database" {
  name                = "sanduba-payment-database"
  resource_group_name = azurerm_cosmosdb_account.sanduba_payment_database_account.resource_group_name
  account_name        = azurerm_cosmosdb_account.sanduba_payment_database_account.name
}

resource "azurerm_cosmosdb_mongo_collection" "sanduba_payment_database_collection" {
  name                = "sanduba-payment-database-collection"
  resource_group_name = azurerm_cosmosdb_mongo_database.sanduba_payment_database.resource_group_name
  account_name        = azurerm_cosmosdb_mongo_database.sanduba_payment_database.account_name
  database_name       = azurerm_cosmosdb_mongo_database.sanduba_payment_database.name

  default_ttl_seconds = "777"
  shard_key           = "uniqueKey"
  throughput          = 400

  index {
    keys   = ["_id"]
    unique = true
  }
}

resource "github_actions_organization_secret" "main_database_connectionstring" {
  secret_name     = "APP_MAIN_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sanduba_main_database.name};Persist Security Info=False;User ID=${random_password.mssql_user.result};Password=${random_password.mssql_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

resource "github_actions_organization_secret" "cart_database_connectionstring" {
  secret_name     = "APP_CART_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = azurerm_redis_cache.sanduba_cart_database.primary_connection_string
}

resource "github_actions_organization_secret" "payment_database_connectionstring" {
  secret_name     = "APP_PAYMENT_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = azurerm_cosmosdb_account.sanduba_payment_database.primary_mongodb_connection_string 
}