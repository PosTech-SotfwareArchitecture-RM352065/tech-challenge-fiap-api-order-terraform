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

provider "random" {
}

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

output "order_database_connectionstring" {
  value = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sanduba_order_database.name};Persist Security Info=False;User ID=${random_uuid.sqlserver_user.result};Password=${random_password.sqlserver_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

resource "github_actions_organization_secret" "secret_order_database_connectionstring" {
  secret_name     = "APP_ORDER_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sanduba_order_database.name};Persist Security Info=False;User ID=${random_uuid.sqlserver_user.result};Password=${random_password.sqlserver_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

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

output "cart_database_connectionstring" {
  value = azurerm_redis_cache.sanduba_cart_database.primary_connection_string
}

data "azurerm_resource_group" "main_group" {
  name = "fiap-tech-challenge-main-group"
}

data "azurerm_virtual_network" "virtual_network" {
  name                = "fiap-tech-challenge-network"
  resource_group_name = data.azurerm_resource_group.main_group.name
}

data "azurerm_subnet" "order_subnet" {
  name                 = "fiap-tech-challenge-order-subnet"
  virtual_network_name = data.azurerm_virtual_network.virtual_network.name
  resource_group_name  = data.azurerm_virtual_network.virtual_network.resource_group_name
}

data "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "fiap-tech-challenge-observability-workspace"
  resource_group_name = "fiap-tech-challenge-observability-group"
}

resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  name                = "fiap-tech-challenge-order-cluster"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  node_resource_group = "fiap-tech-challenge-order-node-group"
  dns_prefix          = "sanduba-order"


  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_B2s"
    vnet_subnet_id = data.azurerm_subnet.order_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_workspace.id
  }

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}