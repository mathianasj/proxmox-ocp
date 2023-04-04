resource "tls_private_key" "bootstrap" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "tls_private_key" "cluster" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "local_file" "bootstrap" {
    content = tls_private_key.bootstrap.private_key_openssh
    filename = "cluster/ansible/${var.cluster_name}_ssh_key"
    file_permission = 0600
}

resource "local_file" "cluster" {
    content = tls_private_key.cluster.private_key_openssh
    filename = "cluster/ansible/${var.cluster_name}_cluster_ssh_key"
    file_permission = 0600
}
