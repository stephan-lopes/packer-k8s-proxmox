source "proxmox-iso" "kubernetes" {
  boot_command             = local.boot_command
  boot_wait                = local.boot_wait
  http_directory           = local.http_directory
  insecure_skip_tls_verify = local.insecure_skip_tls_verify
  proxmox_url              = local.proxmox_url
  username                 = local.username
  token                    = local.token

  node                 = local.node
  tags                 = local.tags
  ssh_username         = local.ssh_username
  ssh_password         = local.ssh_password
  ssh_timeout          = local.ssh_timeout
  template_description = local.template_description
  template_name        = local.template_name
  unmount_iso          = local.unmount_iso
  cores                = local.cores
  memory               = local.memory
  iso_file             = local.iso_file

  disks {
    type         = local.disks.type
    disk_size    = local.disks.disk_size
    storage_pool = local.disks.storage_pool
  }

  network_adapters {
    model         = local.network_adapters.model
    bridge        = local.network_adapters.bridge
    packet_queues = local.network_adapters.packet_queues
  }
}

build {
  sources = [
    "source.proxmox-iso.kubernetes"
  ]

  provisioner "shell" {
    script = "scripts/build_script.sh"
  }

  post-processor "shell-local" {
    script = "scripts/post_build_script.sh"
    environment_vars = [
      "PROXMOX_URL=${local.proxmox_url}",
      "PROXMOX_USERNAME=${local.username}",
      "PROXMOX_TOKEN=${local.token}",
      "VMID=${local.latest_template_vm_id}",
      "TEMPLATE_NAME=${local.template_name}",
      "NODE=${local.node}"
    ]
    execute_command = ["bash", "-c", "{{ .Vars }} {{ .Script }}"]
  }
}
