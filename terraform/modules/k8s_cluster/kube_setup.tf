locals {
  flannel_version       = "0.25.2"
  flannel_manifest = replace(data.http.flannel_cni_manifest.response_body, "10.244.0.0/16", var.pod_network_cidr)
  flannel_manifest_file = "${path.module}/k8s/flannel-cni-v${replace(local.flannel_version, ".", "_")}.yaml"
}


data "http" "flannel_cni_manifest" {
  url = "https://github.com/flannel-io/flannel/releases/download/v${local.flannel_version}/kube-flannel.yml"
}

resource "local_file" "flannel_cni_manifest" {
  filename = local.flannel_manifest_file
  content  = local.flannel_manifest
}

# wait until all control plane and worker nodes have joined
resource "time_sleep" "cluster_ready" {
  depends_on = [ansible_playbook.cluster_worker_join]
  create_duration = "30s"
}

data "kubectl_path_documents" "flannel_cni" {
  pattern = local.flannel_manifest_file
  depends_on = [local_file.flannel_cni_manifest]
}

resource "kubectl_manifest" "flannel_cni" {
  count = length(data.kubectl_path_documents.flannel_cni.documents)
  yaml_body = data.kubectl_path_documents.flannel_cni.documents[count.index]
  depends_on = [time_sleep.cluster_ready]
}
