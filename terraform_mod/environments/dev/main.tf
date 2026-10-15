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

module "dev_namespace" {
  source = "../../modules/namespace"

  namespace_name = var.environment

  labels = {
    environment = var.environment
    managed-by  = var.managed_by
  }
}

## Temporarily disabled as there are no consumers. PVCs require a consumer to be provisioned.
# module "dev_storage" {
#   source = "../../modules/storage"

#   namespace_name = "monitoring-${module.dev_namespace.namespace_name}"

#   persistent_volume_claims = var.pvc_configs_dev

#   labels = {
#     environment = var.environment
#     managed-by  = var.managed_by
#   }
# }

module "dev_networking" {
  source = "../../modules/networking"

  namespace_name = module.dev_namespace.namespace_name

  ingress_resources = var.ingress_resources_dev

  labels = {
    environment = var.environment
    managed-by  = var.managed_by
  }
}

module "dev_monitoring" {
  source = "../../modules/monitoring"

  monitoring_namespace = "monitoring-${module.dev_namespace.namespace_name}"

  enable_grafana              = var.enable_grafana_dev
  enable_prometheus           = var.enable_prometheus_dev
  create_monitoring_namespace = var.create_monitoring_namespace_dev

  labels = {
    environment = var.environment
    managed-by  = var.managed_by
  }
}

module "dev_apps" {
  source = "../../modules/application"

  namespace_name = module.dev_namespace.namespace_name

  deployments = var.deployments_dev

  services = var.services_dev

  labels = {
    environment = var.environment
    managed-by  = var.managed_by
  }
}
