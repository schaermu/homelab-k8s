data "bitwarden_item_secure_note" "sealed_secrets_cert" {
  search = "sealed-secrets-cert@talos"
}

data "bitwarden_item_secure_note" "sealed_secrets_key" {
  search = "sealed-secrets-key@talos"
}

resource "kubernetes_namespace" "sealed-secrets" {
  metadata {
    name = "sealed-secrets"
  }
}

resource "kubernetes_secret" "sealed-secrets-key" {
  depends_on = [kubernetes_namespace.sealed-secrets]

  metadata {
    name      = "sealed-secrets-key4x8nz"
    namespace = "sealed-secrets"
    labels = {
      "sealedsecrets.bitnami.com/sealed-secrets-key" = "active"
    }
  }

  data = {
    "tls.crt" = data.bitwarden_item_secure_note.sealed_secrets_cert.notes
    "tls.key" = data.bitwarden_item_secure_note.sealed_secrets_key.notes
  }

  type = "kubernetes.io/tls"
}
