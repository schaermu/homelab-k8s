# resource "tls_private_key" "argocd" {
#   algorithm   = "ECDSA"
#   ecdsa_curve = "P256"
# }

# resource "github_repository_deploy_key" "this" {
#   title      = "ArgoCD Key"
#   repository = var.github_repository
#   key        = tls_private_key.argocd.public_key_openssh
#   read_only  = "true"
# }

# resource "kubernetes_secret" "ssh_keypair" {
#   metadata {
#     name      = "homelab-k8s-repo"
#     namespace = "argocd"
#     labels = {
#       "argocd.argoproj.io/secret-type" : "repository"
#     }
#   }

#   data = {
#     "type"          = "git"
#     "url"           = "git@github.com:${var.github_org}/${var.github_repository}.git"
#     "sshPrivateKey" = tls_private_key.argocd.private_key_pem
#   }

#   depends_on = [kubernetes_namespace.argocd, github_repository_deploy_key.this]
# }

resource "helm_release" "argocd" {
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.5.3"
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.module}/../../k8s/infra/controllers/argocd/values.yaml")
  ]

  timeout = 600
}

resource "helm_release" "argocd-apps" {
  name = "argocd-apps"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = "argocd"
  version    = "1.6.2"

  values = [
    file("${path.module}/inline-manifests/argocd-apps-values.yaml")
  ]

  depends_on = [helm_release.argocd]
}
