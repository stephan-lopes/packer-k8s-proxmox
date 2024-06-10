variable "proxmox_credentials" {
  description = "proxmox-credentials"
  type = object({
    username    = string
    password    = string
    proxmox_url = string
  })
  sensitive = true
}

# source "proxmox-iso" "kubernetes" 
locals {
  boot_command             = ["<esc> auto preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>"]
  boot_wait                = "10s"
  http_directory           = "config"
  insecure_skip_tls_verify = true
  proxmox_url              = var.proxmox_credentials.proxmox_url
  username                 = var.proxmox_credentials.username
  token                    = var.proxmox_credentials.password

  node                 = "proxmox"
  tags                 = "debian-12;kubernetes;template"
  ssh_username         = "kubernetes"
  ssh_password         = "kubernetes"
  ssh_timeout          = "15m"
  template_description = "Kubernetes v1.30 Template image, generated on ${timestamp()}"
  template_name        = "kubernetes-1.30"
  unmount_iso          = true
  cores                = 2
  memory               = 2048
  iso_file             = "local:iso/debian-12.4.0-amd64-netinst.iso"

  disks = {
    type         = "scsi"
    disk_size    = "30G"
    storage_pool = "local-lvm"
  }

  network_adapters = {
    model         = "virtio"
    bridge        = "vmbr1"
    packet_queues = 2
  }

  latest_template_vm_id = 1000
}
