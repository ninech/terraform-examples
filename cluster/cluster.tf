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
        vcluster = {}
        # for a full nke cluster comment above line and uncomment the following line:
        # nke = {}
        nodePools = []
        location  = "nine-es34"
      }
      writeConnectionSecretToRef = {
        name      = var.name
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
