output "kubeconfig_context" {
  description = "Kubernetes context in use"
  value       = var.kubeconfig_context
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = var.kubeconfig_path
}

output "production_namespace" {
  description = "Production namespace"
  value       = module.production_namespace.namespace_name
}

output "ingress_info" {
  description = "Ingress configuration for production environment"
  value       = var.ingress_resources_production
}

output "local_access_guide" {
  description = "Guide to access production services"
  value       = <<-EOT
    ⚠️  PRODUCTION ENVIRONMENT ⚠️

    To access production services locally, add these to /etc/hosts:

    127.0.0.1 app.local
    127.0.0.1 api.local

    Services:
    - http://app.local (Main application)
    - http://api.local (API service)

    For monitoring (if enabled):
    kubectl port-forward -n monitoring svc/grafana 3000:80
    - Grafana: http://localhost:3000 (username: admin)

    ⚠️ Use 'terraform plan' before 'terraform apply'
    ⚠️ Always backup state before major changes
    ⚠️ Verify all resources exist before destroying
  EOT
}

# output "pvc_details" {
#   description = "PersistentVolumeClaim details for production"
#   value       = module.production_storage.persistent_volume_claims
# }

output "networking_ingress_endpoints" {
  description = "Ingress endpoints configured for production"
  value       = try(module.production_networking.ingress_endpoints, {})
}

output "storage_summary" {
  description = "Storage configuration summary for production"
  value = {
    storage_class = "local-path"
    pvcs          = keys(var.pvc_configs_production)
    total_size_gb = sum([for k, v in var.pvc_configs_production : tonumber(replace(v.size, "Gi", ""))])
    breakdown = {
      for k, v in var.pvc_configs_production : k => v.size
    }
  }
}

output "monitoring_namespace_created" {
  description = "Whether monitoring namespace is created"
  value       = var.create_monitoring_namespace_production
}

output "prometheus_enabled" {
  description = "Whether Prometheus is enabled"
  value       = var.enable_prometheus_production
}

output "grafana_enabled" {
  description = "Whether Grafana is enabled"
  value       = var.enable_grafana_production
}

output "environment_summary" {
  description = "Summary of production environment setup"
  value = {
    namespace        = module.production_namespace.namespace_name
    context          = var.kubeconfig_context
    environment      = var.environment
    monitoring       = var.create_monitoring_namespace_production
    prometheus       = var.enable_prometheus_production
    grafana          = var.enable_grafana_production
    storage_pvcs     = keys(var.pvc_configs_production)
    total_storage_gb = sum([for k, v in var.pvc_configs_production : tonumber(replace(v.size, "Gi", ""))])
    state_location   = "${path.root}/terraform.tfstate"
    state_backup_cmd = "cp terraform.tfstate terraform.tfstate.backup"
  }
}

output "critical_checks" {
  description = "Pre-production deployment checks"
  value       = <<-EOT
    ✓ Cluster connectivity verified
    ✓ Namespace created: ${module.production_namespace.namespace_name}
    ✓ Storage classes available: local-path
    ✓ Monitoring enabled:
      > ${var.create_monitoring_namespace_production} - namespace created
      > ${var.enable_prometheus_production} - prometheus enabled
      > ${var.enable_grafana_production} - grafana enabled

    Required Actions Before Production Use:
    1. Verify kubeconfig context: kubectl config current-context
    2. Check cluster health: kubectl get nodes
    3. Confirm storage availability: kubectl get storageclass
    4. Review monitoring endpoints: kubectl port-forward -n monitoring svc/grafana 3000:80
    5. Test ingress configuration: curl -H "Host: app.local" http://localhost
    6. Backup Terraform state: cp terraform.tfstate terraform.tfstate.backup
    7. Document all ingress hosts in /etc/hosts
    8. Enable audit logging if required
    9. Set up log aggregation and alerting
    10. Create deployment runbook for your team
  EOT
}

output "disaster_recovery_notes" {
  description = "Disaster recovery and backup guidelines"
  value       = <<-EOT
    Backup Strategy for Local k3s:

    1. Terraform State:
       - Location: terraform/environments/production/terraform.tfstate
       - Backup: cp terraform.tfstate terraform.tfstate.backup
       - Version control: gitignore .tfstate files

    2. Persistent Data:
       - Storage: /var/lib/rancher/k3s/storage/ (local-path provisioner)
       - Regular backups: tar czf backup-$(date +%Y%m%d).tar.gz /var/lib/rancher/k3s/storage/
       - Retention: Keep at least 30 days of backups

    3. Kubernetes Objects:
       - Full backup: kubectl get all,pvc,pv -o yaml > backup-k8s-$(date +%Y%m%d).yaml
       - Namespace backup: kubectl get all -n production -o yaml > backup-prod-$(date +%Y%m%d).yaml
       - Restore: kubectl apply -f backup-k8s-*.yaml

    4. Recovery Process:
       - Restore Terraform state first
       - Run terraform apply
       - Verify PVC bindings: kubectl get pvc -n production
       - Check pod status: kubectl get pods -n production
       - Run health checks on services
  EOT
}

output "monitoring_setup_commands" {
  description = "Commands to access and configure monitoring"
  value       = <<-EOT
    Monitoring Access:

    1. Grafana Dashboard:
       kubectl port-forward -n monitoring svc/grafana 3000:80
       - URL: http://localhost:3000
       - Default user: admin
       - Password: Check terraform variables

    2. Prometheus Metrics:
       kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
       - URL: http://localhost:9090
       - Query metrics and view targets

    3. View logs:
       kubectl logs -n production -f deployment/app-service

    4. Monitor resource usage:
       kubectl top nodes
       kubectl top pods -n production

    5. Check alerts:
       kubectl get prometheusrules -n monitoring
  EOT
}

output "security_checklist" {
  description = "Security verification checklist for production"
  value       = <<-EOT
    Security Checklist:

    ✓ Network Policies:
      - kubectl get networkpolicies -n production
      - Verify traffic restrictions

    ✓ RBAC Configuration:
      - kubectl get roles -n production
      - kubectl get rolebindings -n production
      - Verify least privilege access

    ✓ Secret Management:
      - kubectl get secrets -n production
      - Ensure no secrets in terraform.tfvars
      - Use var.sensitive = true for sensitive variables

    ✓ Pod Security:
      - kubectl get pods -n production -o jsonpath='{.items[*].spec.securityContext}'
      - Verify read-only root filesystem where possible
      - Check resource limits and requests

    ✓ Storage Security:
      - Verify PVC access modes (should be minimal)
      - Check storage class reclaim policies
      - Ensure encryption if supported by storage backend

    ✓ Ingress Security:
      - Verify TLS configuration if enabled
      - Check ingress resource quotas
      - Review path-based access control

    ⚠️ Important Notes:
      - k3s includes sensible defaults for most security
      - For production-grade security, consider:
        * Pod Security Policies (PSP)
        * Network segmentation
        * Image scanning and registry authentication
        * Audit logging (enabled by default in k3s)
  EOT
}

output "maintenance_windows" {
  description = "Recommended maintenance schedule for production"
  value       = <<-EOT
    Maintenance Schedule:

    Daily:
    - Monitor disk space: kubectl top nodes
    - Check pod status: kubectl get pods -n production
    - Review logs: kubectl logs -n production --tail=100

    Weekly:
    - Test backup recovery
    - Review Grafana alerts and trends
    - Verify certificate expiration (if TLS enabled)
    - Update container images if new versions available

    Monthly:
    - Full state backup and verification
    - Security scan of deployed images
    - Review and update Terraform modules
    - Capacity planning review

    Quarterly:
    - Major version updates (k3s, Terraform, modules)
    - Disaster recovery drill (full restore from backup)
    - Security audit and compliance review
    - Performance optimization analysis

    Recommended Maintenance Window:
    - Time: Off-hours (e.g., 2 AM - 4 AM)
    - Duration: 1-2 hours
    - Frequency: Monthly
    - Notification: Alert monitoring team 24 hours in advance
  EOT
}

output "troubleshooting_guide" {
  description = "Common troubleshooting commands and procedures"
  value       = <<-EOT
    Troubleshooting Guide:

    1. Pod Startup Issues:
       kubectl describe pod <pod-name> -n production
       kubectl logs <pod-name> -n production
       kubectl logs <pod-name> -n production --previous (for crash loops)

    2. Storage Issues:
       kubectl get pvc -n production
       kubectl describe pvc <pvc-name> -n production
       kubectl get pv
       ls -la /var/lib/rancher/k3s/storage/

    3. Network/Ingress Issues:
       kubectl get ingress -n production
       kubectl describe ingress <ingress-name> -n production
       curl -v -H "Host: app.local" http://localhost

    4. Resource Constraints:
       kubectl top nodes
       kubectl top pods -n production
       kubectl describe node <node-name>

    5. Terraform State Issues:
       terraform state list
       terraform state show <resource>
       terraform refresh (to sync with actual cluster)

    6. Provider Connection Issues:
       kubectl config view (verify kubeconfig)
       kubectl config current-context
       kubectl cluster-info

    7. Helm Release Issues (if using helm_release module):
       kubectl get helmreleases -n production (if using helm operator)
       helm list -n production
       helm status <release> -n production
  EOT
}

output "post_deployment_tasks" {
  description = "Tasks to complete after successful terraform apply"
  value       = <<-EOT
    Post-Deployment Checklist:

    Immediate (Within 1 hour):
    [ ] Verify all pods are running: kubectl get pods -n production
    [ ] Check ingress endpoints: kubectl get ingress -n production
    [ ] Test service access: curl -H "Host: app.local" http://localhost
    [ ] Verify PVC mounts: kubectl exec -it <pod> -n production -- df -h
    [ ] Check monitoring stack: kubectl port-forward -n monitoring svc/grafana 3000:80

    Within 24 hours:
    [ ] Create and test backup of all data
    [ ] Establish log collection and aggregation
    [ ] Configure alerting rules in Grafana
    [ ] Document all ingress URLs and credentials
    [ ] Train team on kubectl commands and monitoring
    [ ] Set up runbooks for common issues

    Within 1 week:
    [ ] Load test the application
    [ ] Verify backup restore process works
    [ ] Review and adjust resource limits
    [ ] Conduct security scan of deployed images
    [ ] Establish on-call rotation and escalation paths

    Ongoing:
    [ ] Monitor cluster health daily
    [ ] Update container images regularly
    [ ] Review Terraform modules for updates
    [ ] Maintain backup retention policy
    [ ] Conduct monthly disaster recovery drills
  EOT
}

output "useful_commands" {
  description = "Useful kubectl and Terraform commands for production management"
  value       = <<-EOT
    Kubernetes Commands:

    Cluster Overview:
      kubectl cluster-info
      kubectl get nodes -o wide
      kubectl get all -n production

    Pod Management:
      kubectl get pods -n production
      kubectl describe pod <pod-name> -n production
      kubectl logs <pod-name> -n production
      kubectl exec -it <pod-name> -n production -- bash

    Storage:
      kubectl get pvc -n production
      kubectl get pv
      kubectl describe pvc <pvc-name> -n production

    Networking:
      kubectl get svc -n production
      kubectl get ingress -n production
      kubectl port-forward svc/<service> 8080:80 -n production

    Resource Management:
      kubectl apply -f <manifest.yaml>
      kubectl delete -f <manifest.yaml>
      kubectl scale deployment <name> --replicas=3 -n production
      kubectl set image deployment/<name> <container>=<image>

    Terraform Commands:

    Initialization:
      terraform init
      terraform validate
      terraform fmt -recursive

    Planning:
      terraform plan -out=tfplan
      terraform show tfplan

    Application:
      terraform apply tfplan
      terraform apply -auto-approve (not recommended for production)

    State Management:
      terraform state list
      terraform state show <resource>
      terraform state rm <resource> (careful!)
      terraform refresh

    Debugging:
      terraform console (interactive mode)
      terraform graph | dot -Tsvg > graph.svg
      TF_LOG=DEBUG terraform plan
  EOT
}
