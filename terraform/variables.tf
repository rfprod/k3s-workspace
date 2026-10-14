variable "apps" {
  type = map(object({
    namespace   = string
    image       = string
    tag         = string
    ports       = map(number)
    replicas    = number
    environment = map(string)
    app_type    = string
  }))
}

variable "ingress_enabled" {
  type    = bool
  default = true
}
