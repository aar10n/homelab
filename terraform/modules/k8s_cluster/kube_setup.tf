locals {
  k8s_root = "${path.module}/manifests"

  flannel_manifest_file       = "${local.k8s_root}/flannel-0_25_2.yaml"
  cert_manager_manifest_file  = "${local.k8s_root}/cert-manager-1_14_5.yaml"
  ingress_nginx_manifest_file = "${local.k8s_root}/ingress-nginx-1_10_1.yaml"
}

resource "time_sleep" "cluster_ready" {
  # wait until all control plane and worker nodes have joined
  depends_on = [ansible_playbook.cluster_worker_join]
  create_duration = "10s"
}

module "kubectl_apply_cni" {
  source = "./modules/kubectl_apply"
  # replace default flannel pod network CIDR with the one specified in the variables
  content = replace(file(local.flannel_manifest_file), "10.244.0.0/16", var.pod_network_cidr)
  depends_on = [time_sleep.cluster_ready]
}

module "kubectl_apply_dependencies" {
  source = "./modules/kubectl_apply"
  for_each = {
    cert-manager  = local.cert_manager_manifest_file
    ingress-nginx = local.ingress_nginx_manifest_file
  }

  file = each.value
  depends_on = [module.kubectl_apply_cni]
}
