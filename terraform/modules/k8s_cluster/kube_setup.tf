locals {
  k8s_root = "${path.module}/manifests"

  flannel_manifest_file = "${local.k8s_root}/flannel-cni.yaml"
  flannel_manifest_documents = split("---", replace(file(local.flannel_manifest_file), local.flannel_default_cidr, var.pod_network_cidr))
  flannel_default_cidr  = "10.244.0.0/16"

  metallb_manifest_file = "${local.k8s_root}/metallb-native.yaml"
  metallb_manifest_documents = split("---", file(local.metallb_manifest_file))
  metallb_has_ips       = var.metallb_address_pool != null

  emissary_crds_manifest_file = "${local.k8s_root}/emissary-crds.yaml"
  emissary_crds_manifest_documents = compact(split("---\n", file(local.emissary_crds_manifest_file)))

  emissary_ns_manifest_file = "${local.k8s_root}/emissary-ns.yaml"
  emissary_ns_manifest_documents = compact(split("---\n", file(local.emissary_ns_manifest_file)))

  emissary_ingress_loadbalancer_status = data.kubernetes_service.emissary_ingress.status[0]["load_balancer"][0]["ingress"]
  emissary_ingress_loadbalancer_ip     = (length(local.emissary_ingress_loadbalancer_status) > 0 ?
    local.emissary_ingress_loadbalancer_status[0]["ip"]
    : null)
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
  wait             = true
  wait_for_rollout = true

  ignore_fields = ["spec.conversion.webhook.clientConfig.caBundle"]
  depends_on = [kubectl_manifest.flannel_cni]
}

resource "kubectl_manifest" "metallb_address_pool" {
  count            = local.metallb_has_ips ? 1 : 0
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
  count            = local.metallb_has_ips ? 1 : 0
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

resource "kubernetes_namespace" "emissary_ns" {
  metadata {
    name = "emissary"
  }
  depends_on = [kubectl_manifest.metallb]
}

resource "kubectl_manifest" "emissary_crds" {
  count = length(local.emissary_crds_manifest_documents)
  yaml_body        = local.emissary_crds_manifest_documents[count.index]
  wait             = true
  wait_for_rollout = true

  depends_on = [kubernetes_namespace.emissary_ns]
}

resource "kubectl_manifest" "emissary_ns" {
  count = length(local.emissary_ns_manifest_documents)
  yaml_body        = local.emissary_ns_manifest_documents[count.index]
  wait             = true
  wait_for_rollout = true

  ignore_fields = ["rules"]
  depends_on = [kubectl_manifest.emissary_crds]
}

resource "kubectl_manifest" "emissary_listener" {
  count = length(var.emissary_port_listeners)
  yaml_body = <<EOF
apiVersion: getambassador.io/v3alpha1
kind: Listener
metadata:
  name: emissary-ingress-listener-${var.emissary_port_listeners[count.index].port}
  namespace: emissary
spec:
  port: ${var.emissary_port_listeners[count.index].port}
  protocol: ${var.emissary_port_listeners[count.index].protocol}
  securityModel: XFP
  hostBinding:
    namespace:
      from: ALL
EOF

  depends_on = [kubectl_manifest.emissary_ns]
}

data "kubernetes_service" "emissary_ingress" {
  metadata {
    name      = "emissary-ingress"
    namespace = "emissary"
  }
  depends_on = [kubectl_manifest.emissary_listener]
}
