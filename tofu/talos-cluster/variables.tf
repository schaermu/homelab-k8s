variable "proxmox" {
  description = "Proxmox VE configuration"
  type = object({
    cluster = string,
    node    = string,
    api_url = string,
  })
}

variable "cluster" {
  description = "Kubernetes cluster configuration"
  type = object({
    name           = string,
    base_vm_id     = optional(number, 100),
    talos_version  = string,
    talos_image_id = string
    datastore      = string,
    install_disk   = optional(string, "/dev/sda")

    network = object({
      virtual_ip = string,
      bridge     = string,
      cidr       = string
      gateway    = string,
      dns        = optional(set(string))
    })
  })
}

variable "controlplane" {
  description = "Control plane node configuration"
  type = object({
    count         = number,
    first_hostnum = number,

    specs = object({
      cpu    = number,
      memory = number
    })
  })
}

variable "workers" {
  description = "Worker node configuration"
  type = object({
    count         = number,
    first_hostnum = number,

    specs = object({
      cpu    = number,
      memory = number,
      disk   = number
    })
  })
}
