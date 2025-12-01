resource "proxmox_virtual_environment_role" "csi" {
  role_id = "KubernetesCSI"

  privileges = [
    "Sys.Audit",
    "VM.Audit",
    "VM.Config.Disk",
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.Audit"
  ]
}

resource "random_password" "csi_user_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "proxmox_virtual_environment_user" "csi" {
  user_id  = "kubernetes-csi@pve"
  comment  = "Managed by Terraform"
  password = random_password.csi_user_password.result
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.csi.role_id
  }
}

resource "proxmox_virtual_environment_user_token" "csi" {
  comment               = "Managed by Terraform"
  token_name            = "csi"
  user_id               = proxmox_virtual_environment_user.csi.user_id
  privileges_separation = false
}

resource "proxmox_virtual_environment_user_token" "ccm" {
  comment               = "Managed by Terraform"
  token_name            = "ccm"
  user_id               = proxmox_virtual_environment_user.csi.user_id
  privileges_separation = false
}
