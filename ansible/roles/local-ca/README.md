## local-ca

This role installs a local certificate authority (CA) as a trusted root on a host.

### Variables

- `local_ca_install_for_k8s`: Install the local CA certificate and key at the
  path `/etc/kubernetes/pki/ca.{crt,key}`. When `true`, the key must be provided. (default: `false`)

The certificate to install must be provided by one of the following variables: 
  - `local_ca_cert`: The certificate content.
  - `local_ca_cert_file`: Path to the certificate file. (required)

The key is required only if `local_ca_install_for_k8s` is `true`. In that case the key must be 
provided by one of the following variables:
- `local_ca_key`: The key content.
- `local_ca_key_file`: Path to the key file.
