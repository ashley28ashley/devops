terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
  }
}

provider "kind" {}

provider "helm" {
  kubernetes {
    config_path = kind_cluster.devops_cluster.kubeconfig_path
  }
}

# 1. Création du cluster Kubernetes en local via Kind
resource "kind_cluster" "devops_cluster" {
  name           = "devops-project-cluster"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }
  }
}

# 2. Build de l'image Docker du worker et injection dans le cluster Kind
resource "null_resource" "build_and_load_image" {
  depends_on = [kind_cluster.devops_cluster]

  # Le provisioner local-exec s'exécute sur ta machine hôte
  provisioner "local-exec" {
    command = "docker build -t devops-project-worker:latest ../ && kind load docker-image devops-project-worker:latest --name devops-project-cluster"
  }
}

# 3. Déploiement automatique de tous les manifestes K8s (Mois 2)
resource "null_resource" "deploy_manifests" {
  depends_on = [null_resource.build_and_load_image]

  provisioner "local-exec" {
    command = "kubectl apply -f ../k8s/"
  }
}

# 4. Déploiement de Prometheus et Grafana via Helm
resource "helm_release" "kube_prometheus_stack" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  
  depends_on = [kind_cluster.devops_cluster]
}
