
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
  }
}

resource "local_file" "kubeconfig" {
  content  = var.kubeconfig
  filename = "${path.root}/kubeconfig"
}

resource "kubernetes_secret" "api_secrets" {
  metadata {
    name = "api-secrets"
  }

  data = {
    ORDER_CONNECTION_STRING = var.order_database_connectionstring
    CART_CONNECTION_STRING  = var.cart_database_connectionstring
    AUTH_SECRET_KEY         = var.authentication_secret_key
    QUEUE_CONNECTION_STRING = var.order_queue_connection_string
  }

  type = "Opaque"
}

resource "kubernetes_config_map" "api_config" {
  metadata {
    name = "api-config"
  }

  data = {
    ASPNETCORE_URLS        = "http://+:8080"
    ASPNETCORE_ENVIRONMENT = var.environment
    ORDER_CONNECTION_TYPE  = "MSSQL"
    CART_CONNECTION_TYPE   = "REDIS"
    AUTH_ISSUER            = "Sanduba.Auth"
    AUTH_AUDIENCE          = "Users"
    PAYMENT_URL            = var.app_payment_url
  }
}

resource "kubernetes_deployment" "api_deployment" {
  metadata {
    name = "sanduba-order-api-deployment"
    labels = {
      app = "sanduba-order-api-deployment"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "sanduba-order-api-deployment"
      }
    }

    template {
      metadata {
        labels = {
          app = "sanduba-order-api-deployment"
        }
      }

      spec {
        container {
          image = "cangelosilima/sanduba-order-api:latest"
          name  = "sanduba-pod-api"

          port {
            container_port = 8080
          }

          env {
            name = "ConnectionStrings__OrderDatabase__Type"
            value_from {
              config_map_key_ref {
                key  = "ORDER_CONNECTION_TYPE"
                name = kubernetes_config_map.api_config.metadata[0].name
              }
            }
          }

          env {
            name = "ConnectionStrings__OrderDatabase__value"
            value_from {
              secret_key_ref {
                key  = "ORDER_CONNECTION_STRING"
                name = kubernetes_secret.api_secrets.metadata[0].name
              }
            }
          }

          env {
            name = "ConnectionStrings__CartDatabase__Type"
            value_from {
              config_map_key_ref {
                key  = "CART_CONNECTION_TYPE"
                name = kubernetes_config_map.api_config.metadata[0].name
              }
            }
          }

          env {
            name = "ConnectionStrings__CartDatabase__Value"
            value_from {
              secret_key_ref {
                key  = "CART_CONNECTION_STRING"
                name = kubernetes_secret.api_secrets.metadata[0].name
              }
            }
          }

          env {
            name = "JwtSettings__SecretKey"
            value_from {
              secret_key_ref {
                key  = "AUTH_SECRET_KEY"
                name = kubernetes_secret.api_secrets.metadata[0].name
              }
            }
          }

          env {
            name = "JwtSettings__Issuer"
            value_from {
              config_map_key_ref {
                key  = "AUTH_ISSUER"
                name = kubernetes_config_map.api_config.metadata[0].name
              }
            }
          }

          env {
            name = "JwtSettings__Audience"
            value_from {
              config_map_key_ref {
                key  = "AUTH_AUDIENCE"
                name = kubernetes_config_map.api_config.metadata[0].name
              }
            }
          }

          env {
            name = "PaymentSettings__BaseUrl"
            value_from {
              config_map_key_ref {
                key  = "PAYMENT_URL"
                name = kubernetes_config_map.api_config.metadata[0].name
              }
            }
          }

          env {
            name = "BrokerSettings__ConnectionString"
            value_from {
              secret_key_ref {
                key  = "QUEUE_CONNECTION_STRING"
                name = kubernetes_secret.api_secrets.metadata[0].name
              }
            }
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }

            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api_service" {
  metadata {
    name = "sanduba-order-api-svc"
    labels = {
      app = "sanduba-order-api-svc"
    }
    annotations = {
      "sevice.beta.kubernetes.io/azure-load-balancer-internal" = "true"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.api_deployment.metadata[0].labels["app"]
    }
    port {
      protocol = "TCP"
      port     = 8080
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_ingress_v1" "api_ingress" {
  metadata {
    name = "sanduba-order-api-ingress"
    labels = {
      app = "sanduba-order-api-ingress"
    }
  }

  spec {
    ingress_class_name = "azure-application-gateway"

    rule {
      http {
        path {
          backend {
            service {
              name = kubernetes_service.api_service.metadata[0].name
              port {
                number = kubernetes_service.api_service.spec[0].port[0].port
              }
            }
          }

          path = "/*"
        }
      }
    }
  }
}