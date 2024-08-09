resource "github_actions_organization_secret" "order_database_connectionstring" {
  secret_name     = "APP_ORDER_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = var.sanduba_order_database_connection_string
}

resource "github_actions_organization_secret" "order_topic_connection_string" {
  secret_name     = "APP_ORDER_TOPIC_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = var.sanduba_order_topic_connection_string
}

resource "github_actions_organization_secret" "cart_database_connectionstring" {
  secret_name     = "APP_CART_DATABASE_CONNECTION_STRING"
  visibility      = "all"
  plaintext_value = var.sanduba_cart_database_connection_string
}