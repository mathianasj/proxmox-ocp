resource "null_resource" "argo_subscription" {
  count = var.enable_gitops && var.release_type == "okd" ? 1 : 0

    triggers = {
      "on_enable_openshift_gitops" = var.enable_gitops,
      "cluster_name" = var.cluster_name
    }

    provisioner "local-exec" {
        command = "export KUBECONFIG=${path.module}/ansible/provisioner/clusters/${var.cluster_name}/kubeconfig && oc apply -f ${path.module}/crs/argo-subscription.yaml"
    }

    provisioner "local-exec" {
        when = destroy
        command = "export KUBECONFIG=${path.module}/ansible/provisioner/clusters/${self.triggers.cluster_name}/kubeconfig && oc delete --ignore-not-found=true -f ${path.module}/crs/argo-subscription.yaml"
    }
}

resource "null_resource" "gitops_subscription" {
  count = var.enable_gitops && var.release_type == "ocp" ? 1 : 0

    triggers = {
      "on_enable_openshift_gitops" = var.enable_gitops
    }

    provisioner "local-exec" {
        command = "export KUBECONFIG=${path.module}/ansible/provisioner/clusters/${var.cluster_name}/kubeconfig && oc apply -f ${path.module}/crs/gitops-subscription.yaml"
    }

    provisioner "local-exec" {
      command = "export KUBECONFIG=${path.module}/ansible/provisioner/clusters/${var.cluster_name}/kubeconfig && oc label namespace openshift-marketplace argocd.argoproj.io/managed-by=openshift-gitops --overwrite"
    }

    depends_on = [
      local_file.provisioner_ansible_inventory
    ]
}

resource "local_file" "cluster_gitops_values" {
  count = var.enable_gitops_config ? 1 : 0
  content = templatefile("cluster/templates/day2-values.yaml",
    {
      repo_url = var.repo_url,
      repo_username = var.repo_username,
      repo_password = var.repo_password,
      cluster_config_repo_url = var.cluster_config_repo_url,
      enable_openshift_gitops = var.release_type == "ocp" ? "true" : "false",
      aws_cred = var.aws_cred,
      aws_vault =  var.aws_vault
    }
  )

  filename = "cluster/ansible/provisioner/files/${var.cluster_name}_day2-values.yaml"
}

resource "null_resource" "cluster_gitops_config" {
  count = var.enable_gitops_config ? 1 : 0

  depends_on = [ 
    null_resource.argo_subscription,
    null_resource.gitops_subscription,
    local_file.cluster_gitops_values
  ]

    triggers = {
      "enable_gitops_config" = var.enable_gitops_config,
      "repo_url" = var.repo_url,
      "repo_username" = var.repo_username,
      "repo_password" = var.repo_password,
      "clusterconfig_repo_url" = var.cluster_config_repo_url,
      "openshiftgitops" = var.enable_gitops_config,
      "awscred" = var.aws_cred,
      "awsvault" = var.aws_vault,
      "cluster_name" = var.cluster_name,
      "path_module" = path.module
    }

    provisioner "local-exec" {
        command = "export KUBECONFIG=${path.module}/ansible/provisioner/clusters/${var.cluster_name}/kubeconfig && helm upgrade --install -n openshift-gitops application --wait -f cluster/ansible/provisioner/files/${var.cluster_name}_day2-values.yaml ${path.module}/day2"
    }

    provisioner "local-exec" {
      when = destroy
      command = "export KUBECONFIG=${self.triggers.path_module}/ansible/provisioner/clusters/${self.triggers.cluster_name}/kubeconfig && helm uninstall application -n openshift-gitops --wait"
    }
}

# resource "helm_release" "cluster_config" {
#   name       = "cluster-config"
#   count = var.enable_gitops ? 0 : 1

#   depends_on = [ 
#     null_resource.argo_subscription,
#     null_resource.gitops_subscription
#   ]

#   chart      = "${path.module}/day2"
#   namespace  = "openshift-gitops"
#   create_namespace = true
#   wait = true
#   wait_for_jobs = true

#   set {
#     name  = "repo.url"
#     value = "${var.repo_url}"
#   }

#   set {
#     name  = "repo.username"
#     value = "${var.repo_username}"
#   }

#   set_sensitive {
#     name  = "repo.password"
#     value = "${var.repo_password}"
#   }

#   set {
#     name  = "clusterconfig.repo.url"
#     value = "${var.cluster_config_repo_url}" 
#   }

#   set {
#     name  = "openshiftgitops"
#     value = "${var.enable_openshift_gitops}"
#   }

#   set {
#     name  = "awscred"
#     value = "${var.aws_cred}"
#   }

#   set {
#     name = "awsvault"
#     value = "${var.aws_vault}"
#   }

# }
