
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.6"
    }
  }
}

locals {
  ipconfig = "ip=${var.ip_address},gw=${var.ip_gateway}"
}

resource "proxmox_vm_qemu" "base" {
  name = var.hostname
  vmid = var.vmid
  tags = var.tags
  desc = var.description

  target_node = var.target_node

  clone      = var.clone_template_name
  full_clone = true

  onboot   = var.onboot
  oncreate = var.oncreate
  tablet   = false
  agent    = 1 # ensure qemu_guest_agent is installed in img

  qemu_os = "l26"
  cores   = var.cores
  sockets = var.sockets
  memory  = var.memory
  scsihw  = "virtio-scsi-pci"

  disk {
    size    = var.disk_size
    type    = "scsi"
    storage = var.disk_storage_pool
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  os_type         = "cloud-init"
  ssh_user        = var.ssh_user
  ssh_private_key = <<EOF
${var.ssh_private_key}
EOF
  ci_wait         = 60
  ciuser          = var.ssh_user
  sshkeys         = var.ssh_public_key
  ipconfig0       = local.ipconfig

  connection {
    type = "ssh"
    user = var.ssh_user
    host = self.ssh_host
  }

  provisioner "remote-exec" {
    inline = [
      "echo Hello World!",
      "ip -br a"
    ]
  }
}

output "ip" {
  value       = proxmox_vm_qemu.base.default_ipv4_address
  description = "IP address"
}
