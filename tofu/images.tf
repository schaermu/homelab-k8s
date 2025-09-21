data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.talos_version
  filters = {
    names = ["qemu-guest-agent", "i915", "iscsi-tools", "util-linux-tools"]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
      }
    }
  })
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
}

resource "proxmox_virtual_environment_download_file" "talos_img" {
  content_type            = "iso"
  node_name               = var.proxmox_node
  datastore_id            = "local"
  url                     = data.talos_image_factory_urls.this.urls.disk_image
  file_name               = "talos-${var.talos_version}.img"
  decompression_algorithm = "zst"
}
