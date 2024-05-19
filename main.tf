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

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "aks-cluster" {
  source  = "./azure"
  home_ip = var.home_ip
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
}

output "kubeconfig_path" {
  value = abspath("${path.root}/kubeconfig")
}