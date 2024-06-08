// ====== Outputs ======

output "instance_ip" {
  value = local.instance_ip
}

output "instance_public_key" {
  value = tls_private_key.instance_ssh_key.public_key_openssh
}

output "instance_private_key" {
  value = tls_private_key.instance_ssh_key.private_key_openssh
}
