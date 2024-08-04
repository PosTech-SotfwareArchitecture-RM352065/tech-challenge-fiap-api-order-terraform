terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
  backend "azurerm" {
    key = "terraform-order.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_resource_group" "main_group" {
  name = "fiap-tech-challenge-main-group"
}
module "aks-cluster" {
  source                       = "./azure"
  main_resource_group          = data.azurerm_resource_group.main_group.name
  main_resource_group_location = data.azurerm_resource_group.main_group.location
  environment                  = data.azurerm_resource_group.main_group.tags["environment"]
  home_ip_address   	         = var.home_ip_address
}

module "github" {
  source                                   = "./github"
  depends_on                               = [module.aks-cluster]
  sanduba_order_database_connection_string = module.aks-cluster.order_database_connectionstring
  sanduba_order_queue_connection_string    = module.aks-cluster.order_queue_connection_string
  sanduba_cart_database_connection_string  = module.aks-cluster.cart_database_connectionstring
}

data "azurerm_kubernetes_cluster" "k8s" {
  depends_on          = [module.aks-cluster]
  name                = "fiap-tech-challenge-order-cluster"
  resource_group_name = "fiap-tech-challenge-order-group"
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.k8s.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
}

module "kubernetes-config" {
  depends_on                      = [module.aks-cluster]
  source                          = "./kubernetes"
  kubeconfig                      = data.azurerm_kubernetes_cluster.k8s.kube_config_raw
  order_database_connectionstring = module.aks-cluster.order_database_connectionstring
  cart_database_connectionstring  = module.aks-cluster.cart_database_connectionstring
  authentication_secret_key       = var.authentication_secret_key
  app_payment_url                 = var.app_payment_url
  order_queue_connection_string   = module.aks-cluster.order_queue_connection_string
  order_public_ip                 = module.aks-cluster.order_public_ip
}

output "kubeconfig_path" {
  value = abspath("${path.root}/kubeconfig")
}