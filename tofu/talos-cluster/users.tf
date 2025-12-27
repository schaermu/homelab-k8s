resource "proxmox_virtual_environment_role" "ccm" {
  role_id = "KubernetesCCM"

  privileges = [
    "Sys.Audit",
    "VM.Audit"
  ]
}

resource "random_password" "ccm_user_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "proxmox_virtual_environment_user" "ccm" {
  user_id  = "kubernetes-ccm@pve"
  comment  = "Managed by Terraform"
  password = random_password.ccm_user_password.result
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.ccm.role_id
  }
}

resource "proxmox_virtual_environment_user_token" "ccm" {
  comment               = "Managed by Terraform"
  token_name            = "ccm"
  user_id               = proxmox_virtual_environment_user.ccm.user_id
  privileges_separation = false
}
