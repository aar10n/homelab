locals {
  k8s_root = "${path.module}/manifests"

  flannel_manifest_file = "${local.k8s_root}/flannel-0_25_2.yaml"
  flannel_manifest_documents = split("---", replace(file(local.flannel_manifest_file), local.flannel_default_cidr, var.pod_network_cidr))
  flannel_default_cidr  = "10.244.0.0/16"

  metallb_manifest_file = "${local.k8s_root}/metallb-native-0_14_5.yaml"
  metallb_manifest_documents = split("---", file(local.metallb_manifest_file))
}

resource "time_sleep" "cluster_ready" {
  # wait until all control plane and worker nodes have joined
  depends_on = [ansible_playbook.cluster_worker_join]
  create_duration = "10s"
}

resource "kubectl_manifest" "flannel_cni" {
  count = length(local.flannel_manifest_documents)
  yaml_body         = local.flannel_manifest_documents[count.index]
  server_side_apply = true
  wait              = true
  wait_for_rollout  = true
  depends_on = [time_sleep.cluster_ready]
}

resource "kubectl_manifest" "metallb" {
  count = length(local.metallb_manifest_documents)
  yaml_body        = local.metallb_manifest_documents[count.index]
  ignore_fields = ["spec.conversion.webhook.clientConfig.caBundle"]
  wait             = true
  wait_for_rollout = true
  depends_on = [kubectl_manifest.flannel_cni]
}

resource "kubectl_manifest" "metallb_address_pool" {
  count            = var.metallb_address_pool != null ? 1 : 0
  yaml_body        = <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: address-pool
  namespace: metallb-system
spec:
  addresses:
  - ${var.metallb_address_pool}
EOF
  wait             = true
  wait_for_rollout = true
  depends_on = [kubectl_manifest.metallb]
}

resource "kubectl_manifest" "metallb_l2_advertisement" {
  count            = var.metallb_address_pool != null ? 1 : 0
  yaml_body        = <<EOF
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
    - address-pool
EOF
  wait             = true
  wait_for_rollout = true
  depends_on = [kubectl_manifest.metallb]
}
