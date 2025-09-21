locals {
  cilium = {
    install = file("${path.module}/inline-manifests/cilium-install.yaml")
    values  = file("${path.module}/../../k8s/infra/cilium/values.yaml")
  }

  controlplanes = {
    for i in range(var.controlplane.count) : format("controlplane-%s", i + 1) => {
      vm_id        = i + var.cluster.base_vm_id
      hostname     = "${var.cluster.name}-cp-${i + 1}"
      tags         = ["talos", "controlplane", var.cluster.name]
      datastore    = var.cluster.datastore
      install_disk = var.cluster.install_disk
      ip_address   = cidrhost(var.cluster.network.cidr, i + var.controlplane.first_hostnum)
      subnet       = split("/", var.cluster.network.cidr)[1]
      cpu          = var.controlplane.specs.cpu
      memory       = var.controlplane.specs.memory
      disk         = var.controlplane.specs.disk
    }
  }

  workers = {
    for i in range(var.workers.count) : format("worker-%s", i + 1) => {
      vm_id        = i + var.controlplane.count + var.cluster.base_vm_id
      hostname     = "${var.cluster.name}-worker-${i + 1}"
      tags         = ["talos", "worker", var.cluster.name]
      datastore    = var.cluster.datastore
      install_disk = var.cluster.install_disk
      ip_address   = cidrhost(var.cluster.network.cidr, i + var.workers.first_hostnum)
      subnet       = split("/", var.cluster.network.cidr)[1]
      cpu          = var.workers.specs.cpu
      memory       = var.workers.specs.memory
      disk         = var.workers.specs.disk
      has_igpu     = i == 0 ? true : false
    }
  }
}
