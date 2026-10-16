# Create Kubernetes Deployments
resource "kubernetes_deployment_v1" "this" {
  for_each = var.deployments

  metadata {
    name      = each.key
    namespace = var.namespace_name
    labels = merge(
      var.labels,
      each.value.labels != null ? each.value.labels : {}
    )
    annotations = each.value.annotations
  }

  spec {
    replicas = each.value.replicas

    selector {
      match_labels = each.value.pod_selector_labels
    }

    template {
      metadata {
        labels = merge(
          each.value.pod_selector_labels,
          var.labels
        )
        annotations = each.value.pod_annotations
      }

      spec {
        service_account_name            = each.value.service_account_name
        automount_service_account_token = each.value.automount_service_account_token

        dynamic "container" {
          for_each = each.value.containers
          content {
            name              = container.value.name
            image             = container.value.image
            image_pull_policy = container.value.image_pull_policy

            dynamic "port" {
              for_each = container.value.ports != null ? container.value.ports : []
              content {
                name           = port.value.name
                container_port = port.value.container_port
                protocol       = port.value.protocol
              }
            }

            dynamic "env" {
              for_each = container.value.env != null ? container.value.env : []
              content {
                name  = env.value.name
                value = env.value.value
              }
            }

            dynamic "env_from" {
              for_each = container.value.env_from != null ? container.value.env_from : []
              content {
                config_map_ref {
                  name = env_from.value.config_map_name
                }
              }
            }

            dynamic "volume_mount" {
              for_each = container.value.volume_mounts != null ? container.value.volume_mounts : []
              content {
                name       = volume_mount.value.name
                mount_path = volume_mount.value.mount_path
                read_only  = volume_mount.value.read_only
              }
            }

            dynamic "resources" {
              for_each = container.value.resources != null ? [container.value.resources] : []
              content {
                limits   = resources.value.limits
                requests = resources.value.requests
              }
            }

            dynamic "liveness_probe" {
              for_each = container.value.liveness_probe != null ? [container.value.liveness_probe] : []
              content {
                initial_delay_seconds = liveness_probe.value.initial_delay_seconds
                period_seconds        = liveness_probe.value.period_seconds
                timeout_seconds       = liveness_probe.value.timeout_seconds
                success_threshold     = liveness_probe.value.success_threshold
                failure_threshold     = liveness_probe.value.failure_threshold

                dynamic "http_get" {
                  for_each = liveness_probe.value.http_get != null ? [liveness_probe.value.http_get] : []
                  content {
                    path   = http_get.value.path
                    port   = http_get.value.port
                    scheme = http_get.value.scheme
                  }
                }

                dynamic "exec" {
                  for_each = liveness_probe.value.exec != null ? [liveness_probe.value.exec] : []
                  content {
                    command = exec.value.command
                  }
                }
              }
            }

            dynamic "readiness_probe" {
              for_each = container.value.readiness_probe != null ? [container.value.readiness_probe] : []
              content {
                initial_delay_seconds = readiness_probe.value.initial_delay_seconds
                period_seconds        = readiness_probe.value.period_seconds
                timeout_seconds       = readiness_probe.value.timeout_seconds
                success_threshold     = readiness_probe.value.success_threshold
                failure_threshold     = readiness_probe.value.failure_threshold

                dynamic "http_get" {
                  for_each = readiness_probe.value.http_get != null ? [readiness_probe.value.http_get] : []
                  content {
                    path   = http_get.value.path
                    port   = http_get.value.port
                    scheme = http_get.value.scheme
                  }
                }

                dynamic "exec" {
                  for_each = readiness_probe.value.exec != null ? [readiness_probe.value.exec] : []
                  content {
                    command = exec.value.command
                  }
                }
              }
            }

            dynamic "security_context" {
              for_each = container.value.security_context != null ? [container.value.security_context] : []
              content {
                allow_privilege_escalation = security_context.value.allow_privilege_escalation
                privileged                 = security_context.value.privileged
                read_only_root_filesystem  = security_context.value.read_only_root_filesystem
                run_as_non_root            = security_context.value.run_as_non_root
                run_as_user                = security_context.value.run_as_user
              }
            }
          }
        }

        dynamic "volume" {
          for_each = each.value.volumes != null ? each.value.volumes : []
          content {
            name = volume.value.name

            dynamic "config_map" {
              for_each = volume.value.config_map != null ? [volume.value.config_map] : []
              content {
                name = config_map.value.name
              }
            }

            dynamic "secret" {
              for_each = volume.value.secret != null ? [volume.value.secret] : []
              content {
                secret_name = secret.value.secret_name
              }
            }

            dynamic "persistent_volume_claim" {
              for_each = volume.value.persistent_volume_claim != null ? [volume.value.persistent_volume_claim] : []
              content {
                claim_name = persistent_volume_claim.value.claim_name
              }
            }

            dynamic "empty_dir" {
              for_each = volume.value.empty_dir ? [1] : []
              content {
                medium = volume.value.empty_dir_medium
              }
            }
          }
        }

        restart_policy                   = each.value.restart_policy
        termination_grace_period_seconds = each.value.termination_grace_period_seconds
        dns_policy                       = each.value.dns_policy
      }
    }

    strategy {
      type = each.value.strategy_type

      dynamic "rolling_update" {
        for_each = each.value.strategy_type == "RollingUpdate" ? [1] : []
        content {
          max_surge       = each.value.max_surge
          max_unavailable = each.value.max_unavailable
        }
      }
    }

    revision_history_limit    = each.value.revision_history_limit
    min_ready_seconds         = each.value.min_ready_seconds
    progress_deadline_seconds = each.value.progress_deadline_seconds
  }

  depends_on = []
}

# Create Services
resource "kubernetes_service_v1" "this" {
  for_each = var.services

  metadata {
    name      = each.key
    namespace = var.namespace_name
    labels = merge(
      var.labels,
      each.value.labels != null ? each.value.labels : {}
    )
    annotations = each.value.annotations
  }

  spec {
    type             = each.value.type
    selector         = each.value.selector
    session_affinity = each.value.session_affinity

    dynamic "port" {
      for_each = each.value.ports
      content {
        name        = port.value.name
        port        = port.value.port
        target_port = port.value.target_port
        protocol    = port.value.protocol
      }
    }
  }

  depends_on = [kubernetes_deployment_v1.this]
}

# Create ConfigMaps
resource "kubernetes_config_map_v1" "this" {
  for_each = var.config_maps

  metadata {
    name      = each.key
    namespace = var.namespace_name
    labels    = var.labels
  }

  data = each.value.data
}

# Create Secrets
resource "kubernetes_secret_v1" "this" {
  for_each = {
    for name, secret in nonsensitive(var.secrets) : name => secret
  }

  metadata {
    name      = each.key
    namespace = var.namespace_name
    labels    = var.labels
  }

  type = each.value.type
  data = each.value.data

  lifecycle {
    ignore_changes = [data]
  }
}
