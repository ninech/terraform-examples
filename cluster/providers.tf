terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "kubernetes" {
  # there are different options on how to authenticate the kubernetes provider with nineapis.ch
  # 1. use the kubeconfig that `nctl auth login <account name>` generates:
  config_path    = "~/.kube/config"
  config_context = "nineapis.ch"
  # 2. use a kubeconfig of an API service account `nctl get asa <name> --print-kubeconfig > asa.yaml`
  # config_path    = "/path/to/asa.yaml"
  # config_context = "nineapis.ch"
}
