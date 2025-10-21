resource "kubernetes_manifest" "sample_cluster" {
  manifest = {
    apiVersion = "infrastructure.nine.ch/v1alpha1"
    kind       = "KubernetesCluster"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      forProvider = {
        nke = {}
        nodePools = [
          {
            name        = "pool02"
            machineType = "nine-standard-2"
            Autoscaling = true
            minNodes    = 1
            maxNodes    = 1
            diskSize    = "20Gi"
          }

        ]
        location = var.location
      }
      writeConnectionSecretToRef = {
        name      = var.name
        namespace = var.namespace
      }
    }
  }

  timeouts {
    create = "25m"
    delete = "25m"
  }

  wait {
    fields = {
      "status.atProvider.apiReady" = "true"
    }
  }
}

resource "kubernetes_manifest" "sample_ksa" {
  manifest = {
    apiVersion = "iam.nine.ch/v1alpha1"
    kind       = "KubernetesServiceAccount"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      forProvider = {
        cluster = {
          name = kubernetes_manifest.sample_cluster.object.metadata.name
        }
      }
      writeConnectionSecretToRef = {
        name      = "${var.name}-ksa"
        namespace = var.namespace
      }
    }
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}

resource "kubernetes_manifest" "sample_kcrb" {
  manifest = {
    apiVersion = "iam.nine.ch/v1alpha1"
    kind       = "KubernetesClustersRoleBinding"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      forProvider = {
        role = "admin"
        subjects = [{
          kind = "ServiceAccount",
          name = kubernetes_manifest.sample_ksa.object.metadata.name
        }]
        clusters = [
          {
            name = kubernetes_manifest.sample_cluster.object.metadata.name
          }
        ]
      }
    }
  }
  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}

data "kubernetes_secret_v1" "cluster_credentials" {
  metadata {
    name      = kubernetes_manifest.sample_ksa.object.spec.writeConnectionSecretToRef.name
    namespace = kubernetes_manifest.sample_ksa.object.spec.writeConnectionSecretToRef.namespace
  }
  depends_on = [kubernetes_manifest.sample_kcrb]
}

output "kubeconfig" {
  sensitive = true
  value     = data.kubernetes_secret_v1.cluster_credentials.data.kubeconfig
}

output "host" {
  sensitive = true
  value     = yamldecode(data.kubernetes_secret_v1.cluster_credentials.data.kubeconfig).clusters.0.cluster.server
}


resource "kubernetes_manifest" "prometheus" {
  manifest = {
    apiVersion = "observability.nine.ch/v1alpha1"
    kind       = "Prometheus"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      forProvider = {
        cluster = {
          name = kubernetes_manifest.sample_cluster.object.metadata.name
        }
        diskSpace = "20Gi"
        replicas  = 2
        access = {
          internal = {
            enabled           = false
            podSelector       = {}
            namespaceSelector = {}
          }
          noExternalAccess = false
        }
      }
    }
  }
  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}


resource "kubernetes_manifest" "loki" {
  manifest = {
    apiVersion = "observability.nine.ch/v1alpha1"
    kind       = "Loki"
    metadata = {
      name      = "demo-loki01"
      namespace = var.namespace
    }
    spec = {
      forProvider = {
        retention    = "720h0m0s"
        allowedCIDRs = ["0.0.0.0/0"]
      }
      writeConnectionSecretToRef = {
        name      = "demo-loki01-credentials"
        namespace = var.namespace
      }
    }
  }
}


resource "kubernetes_manifest" "promtail" {
  manifest = {
    apiVersion = "observability.nine.ch/v1alpha1"
    kind       = "Promtail"
    metadata = {
      name      = "demo-promtail01"
      namespace = var.namespace
    }
    spec = {
      forProvider = {
        cluster = {
          name = kubernetes_manifest.sample_cluster.object.metadata.name
        }
        loki = {
          name      = "demo-loki01"
          namespace = var.namespace
        }
      }
      writeConnectionSecretToRef = {
        name      = "demo-promtail01-credentials"
        namespace = var.namespace
      }
    }
  }

  depends_on = [kubernetes_manifest.loki]
  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}

resource "kubernetes_manifest" "ingress_nginx" {
  manifest = {
    apiVersion = "networking.nine.ch/v1alpha1"
    kind       = "IngressNginx"
    metadata = {
      annotations = {
        "kubernetes.io/tls-acme" = "true"
      }
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      deletionPolicy = "Delete"
      forProvider = {
        appendToXForwardedFor = false
        cluster = {
          name = var.name
        }
        disableSnippetAnnotations = false
        enableModSecurity         = false

        hsts = {
          includeSubdomains = false
        }

        ingressClass          = "nginx"
        isDefaultIngressClass = true
        sslPassthrough        = false
      }
    }
  }
  timeouts {
    create = "25m"
    delete = "25m"
  }
}
