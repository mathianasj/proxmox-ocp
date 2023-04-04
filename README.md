# Proxmox OKD/OCP Provisioner

This set of terraform and ansible allows for the provisioning of OCP / OKD ontop of proxmox using the bare metal installer provisoned method.  This is helpful that the only outside dependencies from the cluster itself is a DNS server with forward and reverse entries. 

## Dependencies

1. Fedora or RHEL machine with terraform and ansible installed
1. Two VLANs bound to the network bridge
    1. One that is public routable (access the internet and machines access the cluster)
    1. One that is not routable but all VMs can be bound to (only the VMs need to talk on this)
1. Static IP reservations (examples in parenthesis to follow below)
    1. 3 for master nodes (192.168.25.5-7)
    1. 1 for API VIP (192.168.25.2)
    1. 1 for Ingress VIP (192.168.25.3)
    1. x for number of workers (192.168.25.4)
    1. 1 for provisioner vm (192.168.25.8)
    1. 1 for bootstrap vm (192.168.25.9)
    1. 1 ip for bmc controller lxc container (192.168.25.10)
1. Subdomain that matches the cluster name ex (cluster-name.example.com) where example.com is the top level domain and cluster-name is the name that will be defined for the cluster.
1. Token user for proxmox
1. Credentials for proxmox able to create and manage vms
1. A pull secret obtained from cloud.redhat.com

## DNS

| Record | Entry                             | Value                             |
| ------ | --------------------------------- | --------------------------------- |
| A      | api.cluster-name.example.com      | 192.168.25.2                      |
| PTR    | 2.25.168.192.in-addr.arpa         | api.cluster-name.example.com.     |
| A      | *.apps.cluster-name.example.com   | 192.168.25.3                      |
| A      | worker-0.cluster-name.example.com | 192.168.25.4                      |
| PTR    | 4.25.168.192.in-addr.arpa         | worker-0.cluster-name.example.com |
| A      | master-0.cluster-name.example.com | 192.168.25.5                      |
| PTR    | 5.25.168.192.in-addr.arpa         | master-0.cluster-name.example.com |
| A      | master-1.cluster-name.example.com | 192.168.25.6                      |
| PTR    | 6.25.168.192.in-addr.arpa         | master-1.cluster-name.example.com |
| A      | master-2.cluster-name.example.com | 192.168.25.7                      |
| PTR    | 7.25.168.192.in-addr.arpa         | master-2.cluster-name.example.com |

## Prereq Steps
1. Create a .env file with the following, replacing the {} sections with appropriate values
    ```
    export PM_USER="{proxmox_user@pam}"
    export PM_PASS="{proxmox_pass_here}"
    export PM_API_URL="https://{server_address_here}:8006/api2/json"
    ```
1. Create a terraform.tfvars file, replacing the {} sections with appropriate values
    ```
    bmc_ip = "{cidr for bmc ip ex. 192.168.25.10/24}"
    bmc_gw = "{gateway for bmc ex 192.168.25.1}"
    bmc_bridge = "{proxmox bridge to attach to bmc lxc ex. vmbr0}"
    bmc_node = "{proxmox host to provision bmc lxc on}"
    bmc_password = "{bmc lxc container root password}"
    bmc_storage = "{proxmox storage name}"
    bmc_vlan_tag = "{vlan to tag the bmc with ex 25}"
    bmc_template = "{path to lxc template ex. local:vztmpl/vzdump-lxc-103-2022_07_01-11_32_48.tar.gz}"

    bmc_user = "{username for the bmc controller api}"
    bmc_pass = "{password for the bmc controller api}"
    proxmox_addr = "{proxmox api server address}"
    proxmox_user = "{proxmox user}"
    proxmox_token_name = "{proxmox token name}"
    proxmox_token_value = "{proxmox token value}"

    template_target_node = "{proxmox host name to create the template on}"
    template_host_ip = "{ip or dns name for the node defined for the template_target_node}"
    template_bridge = "{network bridge to create the template with}"

    clusters = {
        "{cluster name ex. cluster-name}": {
            ingress_vip: "{ingress vip ex. 192.168.25.3}",
            api_vip: "{api vip ex. 192.168.25.2}",
            base_domain: "{base domain example.com}",
            public_network: "{public network cidr ex. 192.168.25.0/24}",
            public_gateway: "{public gateway ex. 192.168.25.1}",
            dns_server: "{dns server that resolves the above entries}",
            release_type: "{okd or ocp}",
            cloudinit_storage_type: "{storage type to save cloudinit drive}",
            bootstrap: {
                target_node: "{target proxmox host}",
                ip_cidr: "{ip of bootstrap ex. 192.168.25.9/24}",
                host_cidr: "{ip of provisioner vm 192.168.25.8/24",
                prov_bridge: "{bridge of provisioner network / non routable}",
                public_bridge: "{bridge of the public routable internet access network}",
                prov_vlan: {vlan of provisioner network / non-routable},
                pub_vlan: {vlan of public routable internet access network}
            },
            master: [
                {
                    target_node = "{target proxmox host}",
                    ram = "16384",
                    cores = "4",
                    ip = "{ip of first master ex. 192.168.25.5}",
                    prefix = "{prefix of ip cidr ex. 24}"
                },
                {
                    target_node = "{target proxmox host}",
                    ram = "16384",
                    cores = "4",
                    ip = "{ip of first master ex. 192.168.25.6}",
                    prefix = "{prefix of ip cidr ex. 24}"
                },
                {
                    target_node = "{target proxmox host}",
                    ram = "16384",
                    cores = "4",
                    ip = "{ip of first master ex. 192.168.25.7}",
                    prefix = "{prefix of ip cidr ex. 24}"
                }
            ],
            worker: [
                {
                    target_node = "{target proxmox host}",
                    ram = "16384",
                    cores = "6",
                    ip = "{ip of first worker ex. 192.168.25.4}",
                    prefix = "{prefix of ip cidr ex. 24}"
                }
            ]
        }
    }

    pull_secret = "{escaped json contents of pull secret from cloud.redhat.com}"
    ```
1. Run `terraform init`
1. Run `terraform apply`
1. Accept to apply changes after reviewing