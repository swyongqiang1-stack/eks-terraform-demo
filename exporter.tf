resource "kubernetes_deployment_v1" "exporter" {
  metadata {
    name = "terraform-exporter"
    labels = {
      test = "exporter"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        test = "exporter"
      }
    }

    template {
      metadata {
        labels = {
          test = "exporter"
        }
      }

      spec {
        container {
          image = "public.ecr.aws/u5u3g3h3/python-exporter:latest"
          name  = "exporter"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          port {
            container_port = 5000
            name = "health"
            }
          port {
            container_port = 8000
            name = "metrics"
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 5000

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}