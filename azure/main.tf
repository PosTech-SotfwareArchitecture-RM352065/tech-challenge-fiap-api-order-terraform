resource "azurerm_resource_group" "resource_group" {
  name     = "fiap-tech-challenge-order-group"
  location = var.main_resource_group_location

  tags = {
    environment = var.environment
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

resource "azurerm_mssql_firewall_rule" "sqlserver_allow_home_ip_rule" {
  name             = "Allow access to Home IP"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = var.home_ip_address
  end_ip_address   = var.home_ip_address
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
  value     = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sanduba_order_database.name};Persist Security Info=False;User ID=${random_uuid.sqlserver_user.result};Password=${random_password.sqlserver_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive = true
}


resource "azurerm_redis_cache" "sanduba_cart_database" {
  name                          = "sanduba-cart-database"
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
  value     = azurerm_redis_cache.sanduba_cart_database.primary_connection_string
  sensitive = true
}

data "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "fiap-tech-challenge-observability-workspace"
  resource_group_name = var.main_resource_group
}

# resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
#   name                = "fiap-tech-challenge-order-cluster"
#   location            = azurerm_resource_group.resource_group.location
#   resource_group_name = azurerm_resource_group.resource_group.name
#   node_resource_group = "fiap-tech-challenge-order-node-group"
#   dns_prefix          = "sanduba-order"
#   depends_on          = [azurerm_mssql_database.sanduba_order_database, azurerm_redis_cache.sanduba_cart_database]

#   default_node_pool {
#     name       = "default"
#     node_count = 1
#     vm_size    = "Standard_B2s"
#   }

#   identity {
#     type = "SystemAssigned"
#   }

#   network_profile {
#     network_plugin    = "azure"
#     network_policy    = "calico"
#     load_balancer_sku = "standard"
#   }

#   oms_agent {
#     log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_workspace.id
#   }

#   tags = {
#     environment = azurerm_resource_group.resource_group.tags["environment"]
#   }
# }

# data "azurerm_resource_group" "resource_group_node" {
#   name       = "fiap-tech-challenge-order-node-group"
#   depends_on = [azurerm_kubernetes_cluster.kubernetes_cluster]
# }

# resource "azurerm_public_ip" "order_public_ip" {
#   name                = "fiap-tech-challenge-order-public-ip"
#   resource_group_name = data.azurerm_resource_group.resource_group_node.name
#   location            = data.azurerm_resource_group.resource_group_node.location
#   allocation_method   = "Static"
#   domain_name_label   = "sanduba-order"
#   sku                 = "Standard"

#   tags = {
#     environment = azurerm_resource_group.resource_group.tags["environment"]
#   }
# }

# output "order_public_ip" {
#   value     = azurerm_public_ip.order_public_ip.ip_address
#   sensitive = false
# }

resource "azurerm_servicebus_namespace" "servicebus_namespace" {
  name                = "fiap-tech-challenge-order-topic-namespace"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

resource "azurerm_servicebus_topic" "servicebus_topic" {
  name         = "fiap-tech-challenge-order-topic"
  namespace_id = azurerm_servicebus_namespace.servicebus_namespace.id
}

resource "azurerm_servicebus_subscription" "topic_subscription" {
  name               = "order-topic-subscription"
  topic_id           = azurerm_servicebus_topic.servicebus_topic.id
  max_delivery_count = 1
}

resource "azurerm_servicebus_topic_authorization_rule" "servicebus_topic_manager" {
  name     = "${azurerm_servicebus_topic.servicebus_topic.name}-manager"
  topic_id = azurerm_servicebus_topic.servicebus_topic.id
  listen   = true
  send     = true
  manage   = true
}

resource "azurerm_servicebus_topic_authorization_rule" "servicebus_topic_publisher" {
  name     = "${azurerm_servicebus_topic.servicebus_topic.name}-publisher"
  topic_id = azurerm_servicebus_topic.servicebus_topic.id
  listen   = false
  send     = true
  manage   = false
}

resource "azurerm_servicebus_topic_authorization_rule" "servicebus_topic_listener" {
  name     = "${azurerm_servicebus_topic.servicebus_topic.name}-listener"
  topic_id = azurerm_servicebus_topic.servicebus_topic.id
  listen   = true
  send     = false
  manage   = false
}

resource "azurerm_container_app_environment" "container_app_environment" {
  name                       = "fiap-tech-challange-order-app-environment"
  location                   = azurerm_resource_group.resource_group.location
  resource_group_name        = azurerm_resource_group.resource_group.name
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_workspace.id
}

resource "azurerm_container_app" "container_app" {
  name                         = "fiap-tech-challange-order-app"
  container_app_environment_id = azurerm_container_app_environment.container_app_environment.id
  resource_group_name          = azurerm_container_app_environment.container_app_environment.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "sanduba-order-api"
      image  = "docker.io/cangelosilima/sanduba-order-api:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      
      env {
        name  = "WEBSITES_ENABLE_APP_SERVICE_STORAGE"
        value = "false"
      }

      env {
        name  = "ASPNETCORE_JwtSettings__SecretKey"
        value = var.authentication_secret_key
      }

      env {
        name  = "ASPNETCORE_JwtSettings__Issuer"
        value = "Sanduba.Auth"
      }

      env {
        name  = "ASPNETCORE_JwtSettings__Audience"
        value = "Users"
      }

      env {
        name  = "ASPNETCORE_ConnectionStrings__OrderDatabase__Type"
        value = "MSSQL"
      }

      env {
        name  = "ASPNETCORE_ConnectionStrings__OrderDatabase_Value"
        value = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sanduba_order_database.name};Persist Security Info=False;User ID=${random_uuid.sqlserver_user.result};Password=${random_password.sqlserver_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
      }

      env {
        name  = "ASPNETCORE_ConnectionStrings__CartDatabase__Type"
        value = "REDIS"
      }

      env {
        name  = "ASPNETCORE_ConnectionStrings__CartDatabase_Value"
        value = azurerm_redis_cache.sanduba_cart_database.primary_connection_string
      }

      env {
        name  = "ASPNETCORE_BrokerSettings__ConnectionString"
        value = azurerm_servicebus_topic_authorization_rule.servicebus_topic_manager.primary_connection_string
      }

      env {
        name  = "ASPNETCORE_BrokerSettings__TopicName"
        value = azurerm_servicebus_topic.servicebus_topic.name
      }

      env {
        name  = "ASPNETCORE_BrokerSettings__SubscriptionName"
        value = azurerm_servicebus_subscription.topic_subscription.name
      }

      env {
        name  = "ASPNETCORE_PaymentSettings__BaseUrl"
        value = "https://sanduba-payment-function.azurewebsites.net"
      }
    }
  }
  
    ingress {
      external_enabled = true    
      target_port      = 8080    
      transport        = "auto"  
      traffic_weight {
        percentage      =  100
        latest_revision = true
      }
    }
}

output "order_topic_connection_string" {
  value     = azurerm_servicebus_namespace.servicebus_namespace.default_primary_connection_string
  sensitive = true
}

output "order_topic_name" {
  value     = azurerm_servicebus_topic.servicebus_topic.name
  sensitive = false
}

output "order_topic_subscription" {
  value     = azurerm_servicebus_subscription.topic_subscription.name
  sensitive = false
}

output "sanduba_order_url" {
  sensitive = false
  value     = "https://${azurerm_container_app.container_app.ingress[0].fqdn}"
}