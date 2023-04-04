variable "bmc_private_key" {
  type = string
}

variable "worker" {
  type = list
  default = []
}

variable "master" {
  type = list
  default = []
}

variable "cluster_name" {
  type = string
}

variable "bmc_ip" {
  type = string
}

variable "bootstrap" {
  type = map
}

variable "bmc_id" {
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

variable "provisioner_template" {
  type = string
}

variable "dns_server" {
  type = string
}

variable "cloudinit_storage" {
  type = string
}

variable "public_gateway" {
  type = string
}

variable "bmc_ansible_init_complete" {
  type = string
}

variable "pull_secret" {
  type = string
}

variable "release_type" {
  type = string
  default = "ocp"
}

variable "okd_release_name" {
  type = string
  default = "4.12.0-0.okd-2023-03-18-084815"
}

variable "okd_release_image" {
  type = string
  default = "quay.io/openshift/okd@sha256:7153ed89133eeaca94b5fda702c5709b9ad199ce4ff9ad1a0f01678d6ecc720f"
}

variable "base_domain" {
  type = string
}

variable "public_network" {
  type = string
}

variable "api_vip" {
  type = string
}

variable "ingress_vip" {
  type = string
}