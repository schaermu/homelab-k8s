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

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [proxmox_virtual_environment_vm.controlplane]
  for_each   = local.controlplanes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value.ip_address
  endpoint                    = each.value.ip_address
  config_patches = [
    templatefile("${path.module}/machine-configs/common.yaml.tftpl", {
      hostname     = each.value.hostname
      install_disk = each.value.install_disk
      node_name    = var.proxmox.node
      cluster_name = var.cluster.name
    }),
    templatefile("${path.module}/machine-configs/controlplane.yaml.tftpl", {
      virtual_ip     = var.cluster.network.virtual_ip
      cilium_values  = local.cilium.values
      cilium_install = local.cilium.install
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
      hostname     = each.value.hostname
      install_disk = each.value.install_disk
      node_name    = var.proxmox.node
      cluster_name = var.cluster.name
    }),
    templatefile("${path.module}/machine-configs/worker.yaml.tftpl", {}),
    file("${path.module}/inline-manifests/user-volume-config.yaml")
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

# talos_cluster_health removed due to https://github.com/siderolabs/terraform-provider-talos/issues/206
resource "time_sleep" "wait_for_cluster" {
  depends_on = [
    talos_machine_bootstrap.this,
    talos_machine_configuration_apply.worker,
    talos_machine_configuration_apply.controlplane
  ]

  create_duration = "10m"
}
