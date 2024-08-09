variable "order_database_connectionstring" {
  type      = string
  sensitive = true
}

variable "cart_database_connectionstring" {
  type      = string
  sensitive = true
}

variable "authentication_secret_key" {
  type      = string
  sensitive = true
}

variable "order_topic_connection_string" {
  type      = string
  sensitive = true
}

variable "order_topic_name" {
  type      = string
  sensitive = true
}

variable "order_topic_subscription" {
  type      = string
  sensitive = false
}

variable "app_payment_url" {
  type      = string
  sensitive = false
}

variable "order_public_ip" {
  type      = string
  sensitive = false
}

variable "environment" {
  type    = string
  default = "Development"
}

variable "kubeconfig" {
  type = string
}