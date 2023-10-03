resource "proxmox_vm_qemu" "fedora35_template" {
    name = "fedora35-template"
    target_node = var.template_target_node
    agent = 1
    oncreate = false
    scsihw = "virtio-scsi-pci"
    pxe = true
    boot = "order=net0"
    qemu_os = "l26"

    network {
        model = "virtio"
        bridge = var.template_bridge
    }

    lifecycle {
      ignore_changes = [
        disk
      ]
    }
}

resource "null_resource" "fedora35_template_import" {
    depends_on = [
      local_file.ansible_inventory
    ]
    
    triggers = {
        templatevmid = split("/",proxmox_vm_qemu.fedora35_template.id)[2],
        template = proxmox_vm_qemu.fedora35_template.name,
        template_url = var.fedora_qcow_url,
        template_storage = var.vm_template_storage
    }

    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i ./ansible/inventory -e vmid=${self.triggers.templatevmid} -e template_url=${self.triggers.template_url} -e template_storage=${self.triggers.template_storage} ./ansible/template/import-template.yaml"
    }
}