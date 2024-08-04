variable "environment" {
  type      = string
  sensitive = false
  default   = ""
}

variable "main_resource_group" {
  type      = string
  sensitive = false
  default   = ""
}

variable "main_resource_group_location" {
  type      = string
  sensitive = false
  default   = ""
}

variable "home_ip_address" {
  type      = string
  sensitive = true
  default   = ""
}