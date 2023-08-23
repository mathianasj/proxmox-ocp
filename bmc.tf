resource "proxmox_lxc" "bmc" {
  target_node   = var.bmc_node
  hostname      = "bmc"
  ostemplate    = "${var.template_storage}:vztmpl/bmc_base.tar.gz"
  password      = var.bmc_password
  unprivileged  = true
  start         = true

  // Terraform will crash without rootfs defined
  rootfs {
    storage = var.bmc_storage
    size    = var.bmc_storage_size
  }

  network {
    name   = "eth0"
    bridge = var.bmc_bridge
    ip     = var.bmc_ip
    tag    = var.bmc_vlan_tag
    gw     = var.bmc_gw
  }

    ssh_public_keys = <<-EOT
        ${ tls_private_key.bmc.public_key_openssh }
    EOT
}

resource "tls_private_key" "bmc" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "local_file" "bmc_ssh_key" {
    content = tls_private_key.bmc.private_key_openssh
    filename = "ansible/bmc/ssh_key"
    file_permission = 0600
}

resource "null_resource" "bmc_ansible_init" {
  depends_on = [
    local_file.ansible_inventory,
    proxmox_lxc.bmc
  ]

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i ./ansible/inventory --private-key ./ansible/bmc/ssh_key ./ansible/bmc/init.yaml"
  }
}
