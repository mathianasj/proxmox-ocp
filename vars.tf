variable "bmc_ip" {
    type = string
}

variable "dns_server" {
    type = string
}

variable "bmc_gw" {
    type = string
}

variable "bmc_bridge" {
    type = string
    default = "vmbr0"
}

variable "bmc_node" {
    type = string
}

variable "bmc_password" {
    type = string
    sensitive = true
}

variable "bmc_storage" {
    type = string
}

variable "bmc_storage_size" {
    type = string
    default = "8G"
}

variable "bmc_vlan_tag" {
    type = string
    default = ""
}

variable "bmc_lxc_template" {
  type = string
  default = "fedora-38-default_20230607_amd64.tar.xz"
}

variable "bmc_lxc_template_ip_cidr" {
  type = string
}

variable "bmc_lxc_template_gateway" {
  type = string
}

variable "bmc_user" {
  type = string
}

variable "bmc_pass" {
  type = string
}

variable "proxmox_addr" {
  type = string
}

variable "proxmox_user" {
  type = string
}

variable "proxmox_token_name" {
  type = string
}

variable "proxmox_token_value" {
  type = string
}

variable "template_target_node" {
  type = string
}

variable "template_host_ip" {
  type = string
  description = "IP of the proxmox host where fedora35 vm template will be created"
}

variable "pull_secret" {
  type = string
}

variable "fedora_qcow_url" {
  type = string
  default = "https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/36/Cloud/x86_64/images/Fedora-Cloud-Base-36-1.5.x86_64.qcow2"
}

variable "template_bridge" {
  type = string
}

variable "clusters" {
  type = map
}

variable "template_storage" {
  type = string
}
