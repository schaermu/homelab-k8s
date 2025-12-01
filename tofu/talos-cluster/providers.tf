terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.88,<1.0.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.9.0,<1.0.0"
    }
  }
}

