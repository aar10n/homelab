locals {
  k8s_root = "${path.module}/manifests"
}

resource "time_sleep" "cluster_ready" {
  # wait until all control plane and worker nodes have joined
  depends_on = [ansible_playbook.cluster_worker_join]
  create_duration = "10s"
}

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

// ====== Flannel ======

locals {
  flannel_manifest_file = "${local.k8s_root}/flannel-cni.yaml"
  flannel_manifest_documents = split("\n---\n", replace(file(local.flannel_manifest_file), local.flannel_default_cidr, var.pod_network_cidr))
  flannel_default_cidr  = "10.244.0.0/16"
}

resource "kubectl_manifest" "flannel_cni" {
  count             = var.enable_cluster_setup ? length(local.flannel_manifest_documents) : 0
  yaml_body         = local.flannel_manifest_documents[count.index]
  server_side_apply = true
  wait              = true
  wait_for_rollout  = true
  depends_on = [time_sleep.cluster_ready]
}

// ====== MetalLB ======

locals {
  metallb_manifest_file = "${local.k8s_root}/metallb-native.yaml"
  metallb_manifest_documents = split("---", file(local.metallb_manifest_file))

  metallb_address_pool_yaml = <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: address-pool
  namespace: metallb-system
spec:
  addresses:
    - ${var.metallb_address_pool}
EOF

  metallb_l2_advertisement_yaml = <<EOF
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
    - address-pool
EOF
}

resource "kubectl_manifest" "metallb" {
  count     = var.enable_cluster_setup ? length(local.metallb_manifest_documents) : 0
  yaml_body = local.metallb_manifest_documents[count.index]
  wait      = true

  ignore_fields = ["spec.conversion.webhook.clientConfig.caBundle"]
  depends_on = [kubectl_manifest.flannel_cni]
}

resource "kubectl_manifest" "metallb_address_pool" {
  count            = var.enable_cluster_setup && var.metallb_address_pool != null ? 1 : 0
  yaml_body        = local.metallb_address_pool_yaml
  wait             = true
  wait_for_rollout = true

  depends_on = [kubectl_manifest.metallb]
}

resource "kubectl_manifest" "metallb_l2_advertisement" {
  count            = var.enable_cluster_setup && var.metallb_address_pool != null ? 1 : 0
  yaml_body        = local.metallb_l2_advertisement_yaml
  wait             = true
  wait_for_rollout = true

  depends_on = [kubectl_manifest.metallb]
}

// ====== OpenEBS ======

resource "helm_release" "openebs" {
  count            = var.enable_cluster_setup ? 1 : 0
  name             = "openebs"
  chart            = "openebs"
  version          = "v4.0.1"
  repository       = "https://openebs.github.io/openebs"
  namespace        = "openebs"
  create_namespace = true
  wait             = true

  dynamic "set" {
    for_each = {
      "engines.local.lvm.enabled" : "false"
      "engines.local.zfs.enabled" : "false"
      "engines.replicated.mayastor.enabled" : "false"
    }
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [kubectl_manifest.flannel_cni]
}

// ====== Contour ======

locals {
  contour_manifest_file = "${local.k8s_root}/contour-gateway.yaml"
  contour_manifest_documents = split("\n---\n", file(local.contour_manifest_file))

  contour_gateway_class_yaml = <<EOF
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: contour
spec:
  controllerName: projectcontour.io/gateway-controller
EOF
}

resource "kubectl_manifest" "contour" {
  count     = var.enable_cluster_setup ? length(local.contour_manifest_documents) : 0
  yaml_body = local.contour_manifest_documents[count.index]
  wait      = true

  depends_on = [kubectl_manifest.metallb]
}

resource "kubectl_manifest" "contour_gateway_class" {
  count            = var.enable_cluster_setup ? 1 : 0
  yaml_body        = local.contour_gateway_class_yaml
  wait             = true
  wait_for_rollout = true

  depends_on = [kubectl_manifest.contour]
}

// ============ Cert Manager ============

resource "helm_release" "cert_manager" {
  count            = var.enable_cluster_setup ? 1 : 0
  name             = "cert-manager"
  chart            = "cert-manager"
  version          = "v1.15.0"
  repository       = "https://charts.jetstack.io"
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "crds.keep"
    value = "false"
  }

  set {
    name  = "extraArgs"
    value = "{--enable-gateway-api}"
  }

  depends_on = [kubectl_manifest.contour]
}

resource "kubernetes_secret" "cloudflare_api_token" {
  count = var.enable_cluster_setup && var.cert_manager_cloudflare_api_token != null ? 1 : 0
  metadata {
    name      = "cloudflare-api-token"
    namespace = "cert-manager"
  }
  data = {
    "api-token" = var.cert_manager_cloudflare_api_token
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "cluster_issuer_letsencrypt" {
  for_each = (var.enable_cluster_setup && var.cert_manager_letsencrypt_issuers.enabled) ? {
    production : "https://acme-v02.api.letsencrypt.org/directory"
    staging : "https://acme-staging-v02.api.letsencrypt.org/directory"
  } : {}

  yaml_body        = <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-${each.key}
spec:
  acme:
    email: ${var.cert_manager_letsencrypt_issuers.email}
    server: ${each.value}
    privateKeySecretRef:
      name: letsencrypt-${each.key}
    solvers:
      - dns01:
          cloudflare:
            email: ${var.cert_manager_letsencrypt_issuers.email}
            apiTokenSecretRef:
              name: cloudflare-api-token
              key: api-token
EOF
  wait             = true
  wait_for_rollout = true

  depends_on = [kubernetes_secret.cloudflare_api_token]
}

// ============ Default Gateway ============

locals {
  gateway_enabled     = (var.default_gateway.enabled && length(var.gateway_listeners) > 0)
  gateway_tls_enabled = (local.gateway_enabled && var.default_gateway.tls.enabled)
  gateway_cert_issuer = "letsencrypt-production"
  gateway_name        = var.default_gateway.name != null ? var.default_gateway.name : "gateway"
  gateway_namespace   = var.default_gateway.namespace != null ? var.default_gateway.namespace : "projectcontour"

  gateway_listeners = [
    for i, lst in var.gateway_listeners : {
      name : lst.name != null ? lst.name : lower(lst.port)
      port : lst.port
      protocol : lst.protocol
      hostname : lst.hostname
      tls : lst.tls != null ? lst.tls : (length(regexall("(HTTPS|TLS)", lst.protocol)) > 0 ? local.gateway_tls : null)
      allowedRoutes : lst.allowedRoutes != null ? lst.allowedRoutes : {
        namespaces : {
          from : "All"
        }
      }
    }
  ]

  gateway_tls = {
    mode : "Terminate"
    certificateRefs : [
      {
        name : "gateway-tls-secret"
        namespace : local.gateway_namespace
      }
    ]
    options = null
  }

  default_gateway_cert_yaml = <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: gateway-tls
  namespace: ${local.gateway_namespace}
spec:
  secretName: gateway-tls-secret
  issuerRef:
    name: ${local.gateway_cert_issuer}
    kind: ClusterIssuer
  commonName: ${jsonencode(var.default_gateway.tls["commonName"])}
  dnsNames: ${jsonencode(var.default_gateway.tls["dnsNames"])}
EOF

  default_gateway_yaml = <<EOF
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: ${local.gateway_name}
  namespace: ${local.gateway_namespace}
spec:
  gatewayClassName: contour
  listeners: ${jsonencode(local.gateway_listeners)}
EOF

  envoy_service_lb_ingress_status = (var.enable_cluster_setup ?
    (data.kubernetes_service.envoy_gateway[0].status != null ?
      data.kubernetes_service.envoy_gateway[0].status[0].load_balancer[0]["ingress"] : []) : [])
  envoy_service_external_ip = (length(local.envoy_service_lb_ingress_status) > 0 ?
    local.envoy_service_lb_ingress_status[0]["ip"] : null)
}

resource "kubectl_manifest" "default_gateway_cert" {
  count     = var.enable_cluster_setup && local.gateway_tls_enabled ? 1 : 0
  yaml_body = local.default_gateway_cert_yaml
  wait      = true

  depends_on = [kubectl_manifest.cluster_issuer_letsencrypt]
}

resource "kubectl_manifest" "default_gateway" {
  count            = var.enable_cluster_setup && local.gateway_enabled ? 1 : 0
  yaml_body        = local.default_gateway_yaml
  wait             = true
  wait_for_rollout = true

  depends_on = [kubectl_manifest.contour_gateway_class]
}

data "kubernetes_service" "envoy_gateway" {
  count = var.enable_cluster_setup && local.gateway_enabled ? 1 : 0
  metadata {
    name      = "envoy-gateway"
    namespace = local.gateway_namespace
  }
}
