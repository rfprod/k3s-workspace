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

module "staging_namespace" {
  source = "../../modules/namespace"

  namespace_name = var.environment

  labels = {
    environment = var.environment
    managed-by  = var.managed_by
  }
}

## Temporarily disabled as there are no consumers. PVCs require a consumer to be provisioned.
# module "staging_storage" {
#   source = "../../modules/storage"

#   namespace_name = module.staging_namespace.namespace_name

#   persistent_volume_claims = var.pvc_configs_staging

#   labels = {
#     environment = var.environment
#     managed-by  = var.managed_by
#   }
# }

module "staging_networking" {
  source = "../../modules/networking"

  namespace_name = module.staging_namespace.namespace_name

  ingress_resources = var.ingress_resources_staging

  labels = {
    environment = var.environment
    managed-by  = var.managed_by
  }
}

module "staging_monitoring" {
  source = "../../modules/monitoring"

  monitoring_namespace = "monitoring-${module.staging_namespace.namespace_name}"

  enable_grafana              = var.enable_grafana_staging
  enable_prometheus           = var.enable_prometheus_staging
  create_monitoring_namespace = var.create_monitoring_namespace_staging

  labels = {
    environment = var.environment
    managed-by  = var.managed_by
  }
}
