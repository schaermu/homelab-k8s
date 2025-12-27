resource "local_file" "talos_config" {
  content         = data.talos_client_configuration.this.talos_config
  filename        = "output/talos-config.yaml"
  file_permission = "0600"
}

resource "local_file" "kube_config" {
  content         = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename        = "output/kube-config.yaml"
  file_permission = "0600"
}

data "bitwarden_folder" "homelab" {
  search = "Homelab"
}

resource "bitwarden_item_secure_note" "kubeconfig" {
  name      = "kubeconfig@${var.cluster.name}"
  notes     = talos_cluster_kubeconfig.this.kubeconfig_raw
  folder_id = data.bitwarden_folder.homelab.id
}

output "client_configuration" {
  value     = data.talos_client_configuration.this
  sensitive = true
}

output "kube_config" {
  value     = talos_cluster_kubeconfig.this
  sensitive = true
}
