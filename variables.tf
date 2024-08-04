variable "environment" {
  type      = string
  sensitive = false
  default   = ""
}

variable "location" {
  type      = string
  sensitive = false
  default   = ""
}

variable "authentication_secret_key" {
  type      = string
  sensitive = true
}


variable "app_payment_url" {
  type      = string
  sensitive = false
}

variable "home_ip" {
  type      = string
  sensitive = true
}