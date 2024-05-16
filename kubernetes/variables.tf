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

variable "app_payment_url" {
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