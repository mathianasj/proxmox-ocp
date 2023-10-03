resource "proxmox_vm_qemu" "worker" {
    count = length(var.worker)
    name = "${var.cluster_name}-worker-${count.index}"
    cores = var.worker[count.index].cores
    memory = var.worker[count.index].ram
    target_node = var.worker[count.index].target_node
    pxe = true
    boot = "order=net0;scsi0"
    agent = 0
    oncreate = false
    scsihw = "virtio-scsi-pci"
    qemu_os = "l26"
    # cpu = "Westmere-IBRS"
    
    network {
        bridge    = var.bootstrap.provisioner_bridge
        firewall  = false
        link_down = false
        model     = "virtio"
        tag       = var.bootstrap.provisioner_vlan
    }

    network {
        bridge    = var.bootstrap.public_bridge
        firewall  = false
        link_down = false
        model     = "virtio"
        tag       = var.bootstrap.public_vlan
    }

    dynamic "network" {
      for_each = var.worker[count.index].extra_nics
      content {
        bridge    = network.value.bridge
        firewall  = false
        link_down = false
        model     = "virtio"
        tag       = network.value.tag
      }
    }

    disk {
        type = "scsi"
        storage = var.worker[count.index].storage
        size = "80G"
        ssd = 1
    }

    lifecycle {
      ignore_changes = [
        boot
      ]
    }

    depends_on = [
      var.provisioner_template
    ]
}

resource "null_resource" "worker_bmc" {
    count = length(var.worker)

    triggers = {
        config = templatefile(
            "templates/bmc.config",
            {
                vmid            = split("/",proxmox_vm_qemu.worker[count.index].id)[2],
                bmc_user        = var.bmc_user,
                bmc_pass        = var.bmc_pass,
                proxmox_addr    = var.proxmox_addr,
                proxmox_user    = var.proxmox_user,
                proxmox_token_name  = var.proxmox_token_name,
                proxmox_token_value = var.proxmox_token_value,
            }
        ),
        vm_id = split("/",proxmox_vm_qemu.worker[count.index].id)[2],
        bmc_ip = var.bmc_ip,
        bmc_private_key = var.bmc_private_key
    }

    connection {
            type        = "ssh"
            user        = "root"
            host        = self.triggers.bmc_ip
            private_key = self.triggers.bmc_private_key
        }
        
    provisioner "remote-exec" {
        inline = [
        "mkdir -p /root/.pbmc/${self.triggers.vm_id}",
        ]
    }

  provisioner "file" {
    content = self.triggers.config
    destination = "/root/.pbmc/${self.triggers.vm_id}/config"

        
    }

    provisioner "remote-exec" {
      inline = [
        "rm -rf /root/.pbmc/${self.triggers.vm_id}",
      ]
      when    = destroy
    }
}