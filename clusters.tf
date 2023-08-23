module "cluster" {
    for_each = var.clusters
    source = "./cluster"

    base_domain = each.value.base_domain
    public_network = each.value.public_network
    api_vip = each.value.api_vip
    ingress_vip = each.value.ingress_vip
    cluster_name = each.key
    release_type = each.value.release_type
    bmc_private_key = tls_private_key.bmc.private_key_openssh
    bmc_ip = split("/", var.bmc_ip)[0]

    cloudinit_storage = each.value.cloudinit_storage_type
    dns_server = each.value.dns_server
    public_gateway = each.value.public_gateway

    bmc_user = var.bmc_user
    bmc_pass = var.bmc_pass
    proxmox_addr = var.proxmox_addr
    proxmox_user = var.proxmox_user
    proxmox_token_name = var.proxmox_token_name
    proxmox_token_value = var.proxmox_token_value

    pull_secret = var.pull_secret

    bootstrap = {
        enable = true,
        target_node = each.value.bootstrap.target_node,
        ram = "22528",
        cores = "6",
        ip_cidr = each.value.bootstrap.ip_cidr,
        host_cidr = each.value.bootstrap.host_cidr,
        provisioner_bridge = each.value.bootstrap.prov_bridge,
        public_bridge = each.value.bootstrap.public_bridge,
        provisioner_vlan = each.value.bootstrap.prov_vlan,
        public_vlan = each.value.bootstrap.pub_vlan,
        storage = each.value.bootstrap.storage
    }

    master = each.value.master
    worker = each.value.worker

    bmc_id = proxmox_lxc.bmc.id
    bmc_ansible_init_complete = null_resource.bmc_ansible_init.id

    provisioner_template = null_resource.fedora35_template_import.triggers.template
    # provisioner_template = "fedora35-template"
}
