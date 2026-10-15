terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig_path)
  config_context = var.kubeconfig_context
}

provider "helm" {
  kubernetes {
    config_path    = pathexpand(var.kubeconfig_path)
    config_context = var.kubeconfig_context
  }
}

module "production_namespace" {
  source = "../../modules/namespace"

  namespace_name = var.environment

  labels = {
    environment = var.environment
    managed-by  = var.managed_by
  }
}

## Temporarily disabled as there are no consumers. PVCs require a consumer to be provisioned.
# module "production_storage" {
#   source = "../../modules/storage"

#   namespace_name = module.production_namespace.namespace_name

#   persistent_volume_claims = var.pvc_configs_production

#   labels = {
#     environment = var.environment
#     managed-by  = var.managed_by
#   }
# }

module "production_networking" {
  source = "../../modules/networking"

  namespace_name = module.production_namespace.namespace_name

  ingress_resources = var.ingress_resources_production

  labels = {
    environment = var.environment
    managed-by  = var.managed_by
  }
}

module "production_monitoring" {
  source = "../../modules/monitoring"

  monitoring_namespace = "monitoring-${module.production_namespace.namespace_name}"

  enable_grafana              = var.enable_grafana_production
  enable_prometheus           = var.enable_prometheus_production
  create_monitoring_namespace = var.create_monitoring_namespace_production

  labels = {
    environment = var.environment
    managed-by  = var.managed_by
  }
}
