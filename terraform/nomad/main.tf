terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.6"
    }
  }
}

provider "proxmox" {
  pm_api_url  = var.proxmox_ip
  pm_user     = var.proxmox_user
  pm_password = var.proxmox_password
}

module "server" {
  source = "../modules/vm"

  hostname    = "server-1"
  vmid        = 110
  target_node = var.target_node

  template_name = var.template_name
  onboot        = var.onboot
  oncreate      = var.oncreate

  cores   = 2
  sockets = 2
  memory  = 2048

  ssh_user        = var.ssh_user
  ssh_private_key = file(var.ssh_private_key_file)
  ssh_public_key  = file(var.ssh_public_key_file)
}

resource "null_resource" "server" {
  triggers = {
    ansible_playbook = md5(file("../../ansible/playbooks/server.yml"))
    server_ids       = "${join(",", module.server.*.ip)}"
  }

  connection {
    type = "ssh"
    user = var.ssh_user
    host = module.server.ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl start nomad",
      "sudo systemctl start consul",
      # "goss -g /tmp/goss.yml validate",
    ]
  }
}

module "client" {
  source = "../modules/vm"
  count  = 0

  hostname    = "client-1"
  vmid        = 111
  target_node = var.target_node

  template_name = var.template_name
  onboot        = var.onboot
  oncreate      = var.oncreate

  cores   = 2
  sockets = 2
  memory  = 4096

  ssh_user        = var.ssh_user
  ssh_private_key = file(var.ssh_private_key_file)
  ssh_public_key  = file(var.ssh_public_key_file)
}
