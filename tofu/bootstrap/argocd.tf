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

  timeout = 600
}
