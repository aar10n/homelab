resource "mikrotik_dns_record" "record" {
  for_each = {
    "postgres.local" : module.postgres_database.instance_ip,
    "example.com" : module.k8s_cluster.gateway_external_ip
    "example1.com" : module.k8s_cluster.gateway_external_ip
    "example2.com" : module.k8s_cluster.gateway_external_ip
  }
  name    = each.key
  address = each.value
  comment = "Managed by Terraform"
  ttl     = 30 # 30s
}
