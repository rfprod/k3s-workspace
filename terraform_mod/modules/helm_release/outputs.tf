output "releases" {
  description = "Helm release resource outputs"
  value = {
    for name, release in helm_release.this : name => {
      id      = release.id
      name    = release.name
      chart   = release.chart
      version = release.version
      status  = release.status
    }
  }
}

output "release_metadata" {
  description = "Helm release metadata"
  value = {
    for name, release in helm_release.this : name => release.metadata
  }
  sensitive = true
}
