variable "bw_email" { type = string }
variable "bw_master_password" {
  type      = string
  sensitive = true
}
variable "bw_client_id" { type = string }
variable "bw_client_secret" {
  type      = string
  sensitive = true
}
variable "bw_server" { type = string }

variable "proxmox_url" { type = string }
variable "proxmox_cluster" { type = string }
variable "proxmox_node" { type = string }
variable "proxmox_api_token" {
  type      = string
  sensitive = true
}
variable "proxmox_user" { type = string }

variable "talos_version" { type = string }

variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}

variable "github_org" { type = string }
variable "github_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}
variable "cloudflare_state_access_key" { type = string }
variable "cloudflare_state_secret_key" {
  type = string
}
variable "cloudflare_state_bucket_name" { type = string }
variable "cloudflare_state_endpoint_url" { type = string }
