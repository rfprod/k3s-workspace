resource "helm_release" "this" {
  for_each = var.helm_releases

  name             = each.key
  repository       = each.value.repository
  chart            = each.value.chart
  version          = each.value.version
  namespace        = each.value.namespace
  create_namespace = each.value.create_namespace

  values = concat(
    each.value.values != null ? each.value.values : [],
    [yamlencode(merge(each.value.set, each.value.set_sensitive))]
  )

  wait                       = each.value.wait
  wait_for_jobs              = each.value.wait_for_jobs
  timeout                    = each.value.timeout
  disable_webhooks           = each.value.disable_webhooks
  force_update               = each.value.force_update
  reuse_values               = each.value.reuse_values
  reset_values               = each.value.reset_values
  cleanup_on_fail            = each.value.cleanup_on_fail
  dependency_update          = each.value.dependency_update
  atomic                     = each.value.atomic
  skip_crds                  = each.value.skip_crds
  render_subchart_notes      = each.value.render_subchart_notes
  disable_openapi_validation = each.value.disable_openapi_validation

  lifecycle {
    ignore_changes = [values]
  }

  depends_on = [var.module_depends_on]
}
