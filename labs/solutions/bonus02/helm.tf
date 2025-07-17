resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = "13.2.9"

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "replicaCount"
    value = 2
  }

  set {
    name  = "resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.cpu"
    value = "60m"
  }

  set {
    name  = "autoscaling.enabled"
    value = true
  }

  set {
    name  = "autoscaling.minReplicas"
    value = 2
  }

  set {
    name  = "autoscaling.maxReplicas"
    value = 4
  }

  set {
    name  = "autoscaling.targetCPUUtilizationPercentage"
    value = 5  # Low threshold for lab demonstration
  }
}
