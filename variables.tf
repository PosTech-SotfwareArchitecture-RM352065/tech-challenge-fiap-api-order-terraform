variable "authentication_secret_key" {
  type      = string
  sensitive = true
}

variable "environment" {
  default = "Development"
}

variable "app_payment_url" {
  type      = string
  sensitive = false
}