resource "proxmox_vm_qemu" "bootstrap" {
    count = var.bootstrap.enable ? 1 : 0
    name = "${var.cluster_name}-bootstrap-${count.index}"
    cores = var.bootstrap.cores
    memory = var.bootstrap.ram
    target_node = var.bootstrap.target_node
    clone = var.provisioner_template
    boot = "order=scsi0"
    agent = 1
    oncreate = true
    full_clone = true
    ciuser = "cloud-user"
    cipassword = "password"
    sshkeys = tls_private_key.bootstrap.public_key_openssh
    nameserver = var.dns_server
    cloudinit_cdrom_storage = var.cloudinit_storage
    os_type = "cloud-init"
    scsihw = "virtio-scsi-pci"
    qemu_os = "l26"


    ipconfig0 = "ip=172.22.0.254/24"
    ipconfig1 = "gw=${var.public_gateway},ip=${var.bootstrap.host_cidr}"

    disk {
        type = "scsi"
        storage = "template"
        size = "40G"
        ssd = 1
    }

    network {
        bridge    = var.bootstrap.provisioner_bridge
        firewall  = false
        link_down = false
        model     = "e1000"
        tag       = var.bootstrap.provisioner_vlan
    }

    network {
        bridge    = var.bootstrap.public_bridge
        firewall  = false
        link_down = false
        model     = "e1000"
        tag       = var.bootstrap.public_vlan
    }

    lifecycle {
      ignore_changes = [
        disk,
        boot
      ]
    }
}

resource "null_resource" "bootstrap_bmc" {
    count = var.bootstrap.enable ? 1 : 0

    depends_on = [
      var.bmc_ansible_init_complete
    ]

    triggers = {
        config = templatefile(
            "templates/bmc.config",
            {
                vmid            = split("/",proxmox_vm_qemu.bootstrap[count.index].id)[2],
                bmc_user        = var.bmc_user,
                bmc_pass        = var.bmc_pass,
                proxmox_addr    = var.proxmox_addr,
                proxmox_user    = var.proxmox_user,
                proxmox_token_name  = var.proxmox_token_name,
                proxmox_token_value = var.proxmox_token_value,
            }
        ),
        vm_id = split("/",proxmox_vm_qemu.bootstrap[count.index].id)[2],
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

resource "local_file" "provisioner_install_config" {
  count = var.bootstrap.enable ? 1 : 0
  content = templatefile("cluster/templates/install-config.yaml",
    {
      api_vip         = var.api_vip,
      ingress_vip     = var.ingress_vip,
      bootstrap_ip    = split("/", var.bootstrap.ip_cidr)[0],
      default_gw      = var.public_gateway,
      public_network  = var.public_network,
      bmc_ip          = var.bmc_ip,
      dns_ip          = var.dns_server,
      cluster_name    = var.cluster_name,
      base_domain     = var.base_domain,
      worker_replicas = length(proxmox_vm_qemu.worker),
      master_replicas = length(proxmox_vm_qemu.master),
      pull_secret     = var.pull_secret,
      ssh_public_key  = chomp(tls_private_key.cluster.public_key_openssh),
      masters = flatten([
        for i, master in proxmox_vm_qemu.master : [{
          vmid      = split("/",master.id)[2],
          boot_mac  = master.network[0].macaddr,
          ip        = var.master[i].ip,
          prefix    = var.master[i].prefix
        }]
      ]),
      workers = flatten([
        for i, worker in proxmox_vm_qemu.worker : [{
          vmid      = split("/",worker.id)[2],
          boot_mac  = worker.network[0].macaddr,
          ip        = var.worker[i].ip,
          prefix    = var.worker[i].prefix
        }]
      ])
    }
  )

  filename = "cluster/ansible/provisioner/files/${var.cluster_name}_install-config.yaml"
}


resource "local_file" "provisioner_ansible_inventory" {
    count = var.bootstrap.enable ? 1 : 0
    content = templatefile("cluster/templates/inventory.tmpl",
        {
            provisioner_ip = split("/", var.bootstrap.host_cidr)[0],
        }
    )
    filename = "cluster/ansible/${var.cluster_name}_inventory"

    depends_on = [
      proxmox_vm_qemu.bootstrap
    ]

    provisioner "local-exec" {
      command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i ./cluster/ansible/${var.cluster_name}_inventory --private-key ./cluster/ansible/${var.cluster_name}_ssh_key -e ocp_version=stable-4.12 -e dns_server='${var.dns_server}' -e release_type=${var.release_type} -e okd_release_name=${var.okd_release_name} -e okd_release_image=${var.okd_release_image} -e cluster_name=${var.cluster_name} -e public_gateway='${var.public_gateway}' -e bootstrap_cidr='${var.bootstrap.host_cidr}' ./cluster/ansible/provisioner/prepare.yaml"
    }
}