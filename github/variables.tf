variable "sanduba_order_database_connection_string" {
  sensitive = true
  type      = string
  default   = ""
}

variable "sanduba_order_topic_connection_string" {
  sensitive = true
  type      = string
  default   = ""
}

variable "sanduba_cart_database_connection_string" {
  sensitive = true
  type      = string
  default   = ""
}

variable "sanduba_order_url" {
  sensitive = false
  type      = string
  default   = ""
}