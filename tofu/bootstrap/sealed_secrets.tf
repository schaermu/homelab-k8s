data "bitwarden_item_secure_note" "sealed_secrets" {
  search = "sealed-secrets@talos"
}

data "bitwarden_attachment" "sealed_secrets_cert" {
  item_id = data.bitwarden_item_secure_note.sealed_secrets.id
  id      = data.bitwarden_item_secure_note.sealed_secrets.attachments[0].id
}

data "bitwarden_attachment" "sealed_secrets_key" {
  item_id = data.bitwarden_item_secure_note.sealed_secrets.id
  id      = data.bitwarden_item_secure_note.sealed_secrets.attachments[1].id
}

resource "kubernetes_secret" "sealed-secrets-key" {
  metadata {
    name      = "sealed-secrets-key"
    namespace = "kube-system"
    labels = {
      "sealedsecrets.bitnami.com/sealed-secrets-key" = "active"
    }
  }

  data = {
    "tls.crt" = data.bitwarden_attachment.sealed_secrets_cert.content
    "tls.key" = data.bitwarden_attachment.sealed_secrets_key.content
  }

  type = "kubernetes.io/tls"
}
