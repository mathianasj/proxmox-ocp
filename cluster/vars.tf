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
  default = "4.13.0-0.okd-2023-06-24-145750"
}

variable "okd_release_image" {
  type = string
  default = "quay.io/openshift/okd@sha256:873c173b9ccb1f78bf2c5aa285227259c373191a722bcc3915375006903088a5"
}

variable "okd_version" {
  type = string
  default = "stable-4.13"
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

variable "enable_gitops" {
  type = bool
}

variable "enable_gitops_config" {
  type = bool
}

variable "repo_url" {
  type = string
  default = ""
}

variable "repo_username" {
  type = string
  default = ""
}

variable "repo_password" {
  type = string
  default = ""
}

variable "cluster_config_repo_url" {
  type = string
  default = ""
}

variable "aws_cred" {
  type = string
  default = ""
}

variable "aws_vault" {
  type = string
  default = ""
}