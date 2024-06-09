locals {
  k8s_root = "${path.module}/manifests"

  flannel_manifest_file = "${local.k8s_root}/flannel-cni.yaml"
  flannel_manifest_documents = split("\n---\n", replace(file(local.flannel_manifest_file), local.flannel_default_cidr, var.pod_network_cidr))
  flannel_default_cidr  = "10.244.0.0/16"

  metallb_manifest_file = "${local.k8s_root}/metallb-native.yaml"
  metallb_manifest_documents = split("\n---\n", file(local.metallb_manifest_file))
  metallb_has_ips       = var.metallb_address_pool != null

  contour_manifest_file = "${local.k8s_root}/contour-gateway.yaml"
  contour_manifest_documents = split("\n---\n", replace(file(local.contour_manifest_file), "/(name(space)?): projectcontour/", "$1: contour"))
  gateway_enabled       = (var.default_gateway.enabled && length(local.gateway_listeners) > 0)
  gateway_listeners     = [
    for i, lst in var.gateway_listeners : {
      name : lower(lst.protocol)
      port : lst.port
      protocol : lst.protocol
      allowedRoutes : {
        namespaces : {
          from : "All"
        }
      }
    }
  ]

  envoy_service_lb_ingress_status = data.kubernetes_service.envoy_gateway[0].status[0].load_balancer[0]["ingress"]
  envoy_service_external_ip       = (length(local.envoy_service_lb_ingress_status) > 0 ?
    local.envoy_service_lb_ingress_status[0]["ip"] : null)
}

resource "time_sleep" "cluster_ready" {
  # wait until all control plane and worker nodes have joined
  depends_on = [ansible_playbook.cluster_worker_join]
  create_duration = "10s"
}

# configure
resource "kubernetes_config_map_v1_data" "coredns_config" {
  count = var.cluster_dns_server != null ? 1 : 0
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }
  data = {
    Corefile : <<EOF
.:53 {
    errors
    health {
        lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
        ttl 30
    }
    prometheus :9153
    forward . ${var.cluster_dns_server}
    cache 30
    loop
    reload
    loadbalance
}
EOF
  }
  force = true
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

resource "kubectl_manifest" "contour" {
  count = length(local.contour_manifest_documents)
  yaml_body        = local.contour_manifest_documents[count.index]
  wait             = true
  wait_for_rollout = true

  depends_on = [kubectl_manifest.metallb]
}

resource "kubectl_manifest" "contour_gateway_class" {
  yaml_body        = <<EOF
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: contour
spec:
  controllerName: projectcontour.io/gateway-controller
EOF
  wait             = true
  wait_for_rollout = true

  depends_on = [kubectl_manifest.contour]
}

resource "kubectl_manifest" "default_gateway" {
  count            = local.gateway_enabled ? 1 : 0
  yaml_body        = <<EOF
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: ${var.default_gateway.name}
  namespace: ${var.default_gateway.namespace}
spec:
  gatewayClassName: contour
  listeners: ${jsonencode(local.gateway_listeners)}
EOF
  wait             = true
  wait_for_rollout = true

  depends_on = [kubectl_manifest.contour_gateway_class]
}

data "kubernetes_service" "envoy_gateway" {
  count = local.gateway_enabled ? 1 : 0
  metadata {
    name      = "envoy-gateway"
    namespace = var.default_gateway.namespace
  }
}
