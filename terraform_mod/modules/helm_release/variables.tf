variable "helm_releases" {
  description = "Helm release configurations"
  type = map(object({
    repository                 = string
    chart                      = string
    version                    = string
    namespace                  = string
    values                     = optional(list(string))
    set                        = optional(map(string), {})
    set_sensitive              = optional(map(string), {})
    create_namespace           = optional(bool, true)
    wait                       = optional(bool, true)
    wait_for_jobs              = optional(bool, false)
    timeout                    = optional(number, 600)
    disable_webhooks           = optional(bool, false)
    force_update               = optional(bool, false)
    reuse_values               = optional(bool, false)
    reset_values               = optional(bool, false)
    cleanup_on_fail            = optional(bool, false)
    dependency_update          = optional(bool, false)
    atomic                     = optional(bool, false)
    skip_crds                  = optional(bool, false)
    render_subchart_notes      = optional(bool, true)
    disable_openapi_validation = optional(bool, false)
  }))
  default = {}
}

variable "module_depends_on" {
  description = "List of resources that the helm releases depend on"
  type        = list(any)
  default     = []
}
