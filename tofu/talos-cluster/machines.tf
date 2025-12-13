resource "proxmox_virtual_environment_vm" "controlplane" {
  for_each = local.controlplanes

  lifecycle {
    ignore_changes = [disk[0].file_id]
  }

  vm_id         = each.value.vm_id
  name          = each.value.hostname
  node_name     = var.proxmox.node
  description   = "Talos controlplane node for ${var.cluster.name} Kubernetes cluster"
  tags          = each.value.tags
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "seabios"

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  network_device {
    bridge = var.cluster.network.bridge
  }

  # system disk with Talos OS
  disk {
    datastore_id = each.value.datastore
    interface    = "scsi0"
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    file_format  = "raw"
    size         = 100
    file_id      = var.cluster.talos_image_id
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = each.value.datastore

    dns {
      servers = var.cluster.network.dns
    }

    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/${each.value.subnet}"
        gateway = var.cluster.network.gateway
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "workers" {
  for_each = local.workers

  lifecycle {
    ignore_changes = [disk[0].file_id]
  }

  vm_id         = each.value.vm_id
  name          = each.value.hostname
  node_name     = var.proxmox.node
  description   = "Talos worker node for ${var.cluster.name} Kubernetes cluster"
  tags          = each.value.tags
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "seabios"

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  network_device {
    bridge = var.cluster.network.bridge
  }

  # system disk with Talos OS
  disk {
    datastore_id = each.value.datastore
    interface    = "scsi0"
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    file_format  = "raw"
    size         = 100
    file_id      = var.cluster.talos_image_id
  }

  # data disk for proxmox csi driver
  disk {
    datastore_id = each.value.datastore
    interface    = "scsi1"
    iothread     = true
    ssd          = true
    size         = each.value.disk
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = each.value.datastore

    dns {
      servers = var.cluster.network.dns
    }

    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/${each.value.subnet}"
        gateway = var.cluster.network.gateway
      }
    }
  }

  dynamic "hostpci" {
    for_each = each.value.has_igpu ? [1] : []
    content {
      # Passthrough iGPU
      device  = "hostpci0"
      mapping = "iGPU"
      pcie    = true
      rombar  = true
      xvga    = false
    }
  }
}
