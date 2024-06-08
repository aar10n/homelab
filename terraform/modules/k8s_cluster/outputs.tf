// ====== Outputs ======

output "cluster_ip" {
  value = var.cluster_ip
}

output "cluster_endpoint" {
  value = local.cluster_endpoint
}

output "cluster_admin_token" {
  value     = local.cluster_admin_token
  sensitive = true
}

output "cluster_join_token" {
  value     = local.cluster_join_token
  sensitive = true
}

output "cluster_kubeconfig" {
  value     = ssh_sensitive_resource.cluster_kubeconfig.result
  sensitive = true
}

output "node_ips" {
  value = concat(local.control_plane_ips, local.worker_node_ips)
}

output "node_password" {
  value     = random_password.node_password.result
  sensitive = true
}

output "node_public_key" {
  value = tls_private_key.node_ssh_key.public_key_openssh
}

output "node_private_key" {
  value     = tls_private_key.node_ssh_key.private_key_openssh
  sensitive = true
}

output "emissary_load_balancer_ip" {
  value = local.emissary_ingress_loadbalancer_ip
}
