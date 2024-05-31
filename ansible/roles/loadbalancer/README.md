## loadbalancer

This role configures a simple round-robin load balancer using HAProxy.

### Variables
- `loadbalancer_service_name`: The name of the service to load balance. (default: `service`)
- `loadbalancer_service_port`: The port to load balance. (default: `80`)
- `loadbalancer_backend_servers`: A list of backend servers to load balance. Each item in the list should be a dictionary with the keys:
  - `name`: The name of the server.
  - `ip`: The IP address of the server.
  - `port`: The src port of the server.
