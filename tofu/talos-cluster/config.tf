resource "talos_machine_secrets" "this" {
  talos_version = var.cluster.talos_version
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster.name
  cluster_endpoint = "https://${var.cluster.network.virtual_ip}:6443"
  talos_version    = var.cluster.talos_version
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster.name
  cluster_endpoint = "https://${var.cluster.network.virtual_ip}:6443"
  talos_version    = var.cluster.talos_version
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes = setunion([
    for _, controlplane in local.controlplanes : controlplane.ip_address
    ], [
    for _, worker in local.workers : worker.ip_address
  ])
  endpoints = [for _, controlplane in local.controlplanes : controlplane.ip_address]
}

resource "terraform_data" "inline_manifests" {
  input = [
    {
      name     = "cilium-bootstrap"
      contents = file("${local.cilium.install}")
    },
    {
      name = "cilium-values"
      contents = yamlencode({
        apiVersion = "v1"
        kind       = "ConfigMap"
        metadata = {
          name      = "cilium-values"
          namespace = "kube-system"
        }
        data = {
          "values.yaml" = file("${local.cilium.values}")
        }
      })
    },
    {
      name = "proxmox-cloud-controller-manager"
      contents = yamlencode({
        apiVersion = "v1"
        kind       = "Secret"
        type       = "Opaque"
        metadata = {
          name      = "proxmox-cloud-controller-manager"
          namespace = "kube-system"
        }
        stringData = {
          "config.yaml" = <<EOF
clusters:
  - url: ${var.proxmox.api_url}
    insecure: false
    token_id: "${proxmox_virtual_environment_user_token.ccm.id}"
    token_secret: "${element(split("=", proxmox_virtual_environment_user_token.ccm.value), length(split("=", proxmox_virtual_environment_user_token.ccm.value)) - 1)}"
    region: ${var.proxmox.cluster}
EOF
        }
      })
    },
    {
      name = "proxmox-csi-plugin"
      contents = yamlencode({
        apiVersion = "v1"
        kind       = "Secret"
        type       = "Opaque"
        metadata = {
          name      = "proxmox-csi-plugin"
          namespace = "csi-proxmox"
        }
        stringData = {
          "config.yaml" = <<EOF
clusters:
  - url: ${var.proxmox.api_url}
    insecure: false
    token_id: "${proxmox_virtual_environment_user_token.csi.id}"
    token_secret: "${element(split("=", proxmox_virtual_environment_user_token.csi.value), length(split("=", proxmox_virtual_environment_user_token.csi.value)) - 1)}"
    region: ${var.proxmox.cluster}
EOF
        }
      })
    },
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [proxmox_virtual_environment_vm.controlplane]
  for_each   = local.controlplanes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value.ip_address
  endpoint                    = each.value.ip_address
  config_patches = [
    templatefile("${path.module}/machine-configs/common.yaml.tftpl", {
      hostname         = each.value.hostname
      install_disk     = each.value.install_disk
      pve_cluster_name = var.proxmox.cluster
      pve_node_name    = var.proxmox.node
    }),
    templatefile("${path.module}/machine-configs/controlplane.yaml.tftpl", {
      virtual_ip       = var.cluster.network.virtual_ip
      extra_manifests  = jsonencode(local.extra_manifests)
      inline_manifests = jsonencode(terraform_data.inline_manifests.output)
    })
  ]

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.controlplane[each.key]]
  }
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [proxmox_virtual_environment_vm.workers]
  for_each   = local.workers

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value.ip_address
  endpoint                    = each.value.ip_address
  config_patches = [
    templatefile("${path.module}/machine-configs/common.yaml.tftpl", {
      hostname         = each.value.hostname
      install_disk     = each.value.install_disk
      pve_cluster_name = var.proxmox.cluster
      pve_node_name    = var.proxmox.node
    }),
    templatefile("${path.module}/machine-configs/worker.yaml.tftpl", {})
  ]

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.workers[each.key]]
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.controlplane]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplanes[keys(local.controlplanes)[0]].ip_address
  endpoint             = local.controlplanes[keys(local.controlplanes)[0]].ip_address
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplanes[keys(local.controlplanes)[0]].ip_address
  endpoint             = var.cluster.network.virtual_ip
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_bootstrap.this,
    talos_machine_configuration_apply.worker,
    talos_machine_configuration_apply.controlplane
  ]

  client_configuration = data.talos_client_configuration.this.client_configuration
  control_plane_nodes  = [for _, controlplane in local.controlplanes : controlplane.ip_address]
  worker_nodes         = [for _, worker in local.workers : worker.ip_address]
  endpoints            = data.talos_client_configuration.this.endpoints

  timeouts = {
    read = "10m"
  }
}
