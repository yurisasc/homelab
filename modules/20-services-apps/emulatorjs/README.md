# EmulatorJS Module

This module deploys [EmulatorJS](https://github.com/linuxserver/docker-emulatorjs), a self-hosted retro gaming emulation platform, as a Docker container in the homelab environment.

## Overview

The EmulatorJS module:

- Deploys the `linuxserver/emulatorjs` Docker container
- Persists configuration and game data to volumes on the host
- Exposes multiple ports for frontend, configuration, and backend services
- Provides service definition for integration with networking modules

## Usage

```hcl
module "emulatorjs" {
  source      = "./modules/20-services-apps/emulatorjs"
  volume_path = "/path/to/volumes/emulatorjs"
}
```

## Variables

| Variable      | Description                                  | Type     | Default    |
| ------------- | -------------------------------------------- | -------- | ---------- |
| `image_tag`   | Tag of the EmulatorJS image to use           | `string` | `"latest"` |
| `volume_path` | Host path for EmulatorJS data volumes        | `string` | -          |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "emulatorjs"
  primary_port = <frontend_port>
  endpoint     = "http://emulatorjs:<frontend_port>"
}
```

Note that unlike other services, EmulatorJS doesn't specify subdomains or a publish method in its service definition. This may require manual configuration in your networking setup.

## Ports

EmulatorJS exposes three ports, which are mapped to host ports defined in the `.env` file:

1. Frontend (port 80) - The main web interface for accessing games
2. Config (port 3000) - The configuration interface
3. Backend (port 4001) - Backend services

## Environment Variables

This module requires the following environment variables to be set in a `.env` file:

- `EMULATORJS_FRONTEND_PORT`: Host port for the main web interface
- `EMULATORJS_CONFIG_PORT`: Host port for the configuration interface
- `EMULATORJS_BACKEND_PORT`: Host port for backend services

## Data Persistence

EmulatorJS stores its data in two volumes:

1. Configuration: `/config` in the container, mapped to `${volume_path}/config` on the host
2. Game data: `/data` in the container, mapped to `${volume_path}/data` on the host

## Example Integration in Main Configuration

```hcl
module "emulatorjs" {
  source      = "./modules/20-services-apps/emulatorjs"
  volume_path = module.system_globals.volume_host
}

# If you want to expose EmulatorJS via your networking modules,
# you may need to manually configure the service definition:
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.emulatorjs.service_definition,
    # Other service definitions
  ]
}
```

## Additional Configuration

After deployment, you can access the configuration interface at `http://your-server:<config_port>` to:

1. Upload ROM files to the `/data/roms` directory
2. Configure emulation settings
3. Manage game art and metadata
