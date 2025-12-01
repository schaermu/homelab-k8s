terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket                      = var.cloudflare_state_bucket_name
    key                         = "talos-cluster/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    access_key                  = var.cloudflare_state_access_key
    secret_key                  = var.cloudflare_state_secret_key
    endpoints                   = { s3 = var.cloudflare_state_endpoint_url }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.88,<1.0.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.9.0,<1.0.0"
    }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">=0.16.0,<1.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.38.0,<3.0.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    github = {
      source  = "integrations/github"
      version = ">=6.6.0,<7.0.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">=4,<5"
    }
  }
}

data "bitwarden_item_ssh_key" "proxmox" {
  search = "terraform@proxmox"
}

provider "bitwarden" {
  email           = var.bw_email
  master_password = var.bw_master_password
  client_id       = var.bw_client_id
  client_secret   = var.bw_client_secret
  server          = var.bw_server

  experimental {
    embedded_client = true
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_url
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    agent       = false
    private_key = <<EOF
${data.bitwarden_item_ssh_key.proxmox.private_key}
EOF
    username    = var.proxmox_user
  }
}

provider "talos" {}

provider "kubernetes" {
  host                   = module.talos_cluster.kube_config.kubernetes_client_configuration.host
  client_certificate     = base64decode(module.talos_cluster.kube_config.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos_cluster.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos_cluster.kube_config.kubernetes_client_configuration.ca_certificate)
  ignore_labels = [
    "app.kubernetes.io/.*",
    "kustomize.toolkit.fluxcd.io/.*",
  ]
}

provider "kubectl" {
  host                   = module.talos_cluster.kube_config.kubernetes_client_configuration.host
  client_certificate     = base64decode(module.talos_cluster.kube_config.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos_cluster.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos_cluster.kube_config.kubernetes_client_configuration.ca_certificate)
  load_config_file       = false
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}

provider "helm" {
  kubernetes = {
    host                   = module.talos_cluster.kube_config.kubernetes_client_configuration.host
    client_certificate     = base64decode(module.talos_cluster.kube_config.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(module.talos_cluster.kube_config.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(module.talos_cluster.kube_config.kubernetes_client_configuration.ca_certificate)
  }
}

provider "cloudflare" {
}
