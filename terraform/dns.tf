resource "mikrotik_dns_record" "record" {
  for_each = {
    "postgres.home.agb.dev" : module.postgres_database.instance_ip
    "grafana.home.agb.dev" : module.k8s_cluster.gateway_external_ip
  }
  name    = each.key
  address = each.value
  comment = "Managed by Terraform"
  ttl     = 30 # 30s
}
