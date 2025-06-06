# Docker Network Module

This module creates a Docker network that allows containers to communicate with each other using container names as hostnames.

## Purpose

The module is designed to create a consistent Docker network for all homelab services, enabling direct container-to-container communication using container names instead of IP addresses.

## Usage

```hcl
module "homelab_network" {
  source = "../modules/01-networking/docker-network"
  
  network_name = "homelab-network"
  driver       = "bridge"
  
  # Optional: Configure specific subnet (uncomment if needed)
  # subnet       = "172.20.0.0/16"
  # gateway      = "172.20.0.1"
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `network_name` | Name of the Docker network | `string` | N/A | Yes |
| `driver` | Network driver to use | `string` | `"bridge"` | No |
| `internal` | Restrict external access if true | `bool` | `false` | No |
| `attachable` | Enable manual container attachment | `bool` | `true` | No |
| `ipam_driver` | IP address management driver | `string` | `"default"` | No |
| `subnet` | Subnet in CIDR format | `string` | `""` | No |
| `gateway` | Gateway IP for the subnet | `string` | `""` | No |
| `ip_range` | Range for container IP allocation | `string` | `""` | No |
| `aux_address` | Auxiliary addresses for driver | `map(string)` | `{}` | No |
| `labels` | Docker labels to add to the network | `map(string)` | `{}` | No |
| `options` | Driver-specific options | `map(string)` | `{}` | No |

## Outputs

| Name | Description |
|------|-------------|
| `network_id` | The ID of the created Docker network |
| `network_name` | The name of the Docker network |
| `network_driver` | The driver of the Docker network |
| `ipam_config` | The IPAM configuration of the network |
