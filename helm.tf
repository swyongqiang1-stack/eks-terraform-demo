resource "helm_release" "kube_prometheus_stack" {
  name             = "kps"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "87.6.0"

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "grafana.adminPassword"
    value = "admin123"
  }

  depends_on = [aws_eks_node_group.node]
}