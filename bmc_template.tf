

resource "null_resource" "prepare_bmc_template" {
  depends_on = [
    local_file.ansible_inventory,
    proxmox_lxc.bmc_base_template
  ]

  triggers = {
      template_storage = var.template_storage,
      bmc_lxc_template = var.bmc_lxc_template
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i ./ansible/inventory -e template_storage=${self.triggers.template_storage} -e bmc_lxc_template=${self.triggers.bmc_lxc_template} ./ansible/container/download-base-container.yaml"
  }
}

resource "proxmox_lxc" "bmc_base_template" {
  depends_on = [ 
    null_resource.prepare_bmc_template
  ]
  target_node = var.template_target_node
  hostname      = "bmc-base-template"
  ostemplate    = "${var.template_storage}:vztmpl/${var.bmc_lxc_template}"
  password      = var.bmc_password
  unprivileged  = true
  start         = true

  // Terraform will crash without rootfs defined
  rootfs {
    storage = var.vm_template_storage
    size    = var.bmc_storage_size
  }

  network {
    name   = "eth0"
    bridge = var.bmc_bridge
    ip     = var.bmc_lxc_template_ip_cidr
    tag    = var.bmc_vlan_tag
    gw     = var.bmc_lxc_template_gateway
  }

    ssh_public_keys = <<-EOT
        ${ tls_private_key.bmc.public_key_openssh }
    EOT
}

resource "null_resource" "bmc_template_enable_ssh" {
  depends_on = [
    local_file.ansible_inventory,
    proxmox_lxc.bmc_base_template
  ]

  triggers = {
      template_storage = var.template_storage,
      ct_id = split("/", proxmox_lxc.bmc_base_template.id)[2] 
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i ./ansible/inventory -e template_storage=${self.triggers.template_storage} -e ct_id=${self.triggers.ct_id} ./ansible/container/enable-base-ssh.yaml"
  }
}