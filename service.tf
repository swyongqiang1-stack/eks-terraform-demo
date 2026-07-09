resource "kubernetes_service" "exporter" {
  metadata {
    name = "terraform-exporter"
  }
  spec {
    selector = {
      test = "exporter" 
    }
    session_affinity = "None"
    port {
      port        = 8000
      target_port = 8000
    }

    type = "LoadBalancer"
  }
}
