resource "local_file" "ansible_inventory" {
    content = templatefile("./templates/inventory.tmpl",
        {
            bmc_host = split("/", var.bmc_ip)[0],
            template_host = var.template_host_ip
        }
    )
    filename = "ansible/inventory"
}