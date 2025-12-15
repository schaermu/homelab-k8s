module "talos_cluster" {
  source = "./talos-cluster"

  depends_on = [
    proxmox_virtual_environment_download_file.talos_img,
  ]

  providers = {
    proxmox = proxmox
    talos   = talos
  }

  proxmox = {
    cluster = var.proxmox_cluster
    node    = var.proxmox_node
    api_url = var.proxmox_url
  }

  cluster = {
    name           = "k8s-homelab"
    base_vm_id     = 100
    talos_version  = var.talos_version
    talos_image_id = proxmox_virtual_environment_download_file.talos_img.id
    datastore      = "local-vms"

    network = {
      virtual_ip = "192.168.1.30"
      bridge     = "vmbr0"
      cidr       = "192.168.1.0/24"
      gateway    = "192.168.1.1"
      dns        = ["192.168.1.206"]
    }
  }

  controlplane = {
    count         = 3
    first_hostnum = 31

    specs = {
      cpu    = 2
      memory = 8192
      disk   = 128
    }
  }

  workers = {
    count         = 3
    first_hostnum = 35

    specs = {
      cpu    = 2
      memory = 16384
      disk   = 128
    }
  }
}

module "bootstrap" {
  source = "./bootstrap"

  depends_on = [
    module.talos_cluster,
  ]

  providers = {
    kubernetes = kubernetes
    bitwarden  = bitwarden
    helm       = helm
    github     = github
  }

  github_org        = "schaermu"
  github_repository = "homelab-k8s"
}
