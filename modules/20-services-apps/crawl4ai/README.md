# Crawl4AI Module

This module deploys [Crawl4AI](https://github.com/unclecode/crawl4ai), a web crawling and AI analysis tool, as a Docker container in the homelab environment.

## Overview

The Crawl4AI module:

- Deploys the `unclecode/crawl4ai` Docker container
- Configures resource limits and reservations for memory
- Provides shared memory access for Chrome/Chromium performance
- Supports custom configuration through volume mounting
- Provides service definition for integration with networking modules

## Usage

```hcl
module "crawl4ai" {
  source      = "./modules/20-services-apps/crawl4ai"
  volume_path = "/path/to/volumes"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable              | Description                                       | Type           | Default     |
| --------------------- | ------------------------------------------------- | -------------- | ----------- |
| `image_tag`           | Tag of the Crawl4AI image to use                  | `string`       | `"latest"`  |
| `volume_path`         | Host path for Crawl4AI data volumes               | `string`       | -           |
| `networks`            | List of networks to attach the container to       | `list(string)` | `[]`        |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "crawl4ai"
  primary_port = 11235
  endpoint     = "http://crawl4ai:11235"
}
```

## Environment Variables

Crawl4AI requires API keys for various LLM providers. These are configured through a `.env` file in the module directory. You should create this file based on the provided `.env.example` template:

- `OPENAI_API_KEY`: OpenAI API key
- `DEEPSEEK_API_KEY`: DeepSeek API key 
- `ANTHROPIC_API_KEY`: Anthropic API key
- `GROQ_API_KEY`: Groq API key
- `TOGETHER_API_KEY`: Together API key
- `MISTRAL_API_KEY`: Mistral API key
- `GEMINI_API_TOKEN`: Gemini API token

## Configuration

Crawl4AI requires a custom configuration file. This is mounted from `${volume_path}/crawl4ai/config.yml` to `/app/config.yml` in the container.

## Ports

Crawl4AI exposes one port, which is mapped to host ports defined in the `.env` file:
1. Frontend (port 11235) - The main web interface for accessing games

## Example Integration in Main Configuration

```hcl
module "crawl4ai" {
  source       = "./modules/20-services-apps/crawl4ai"
  volume_path  = module.system_globals.volume_host
  networks     = [module.services.homelab_docker_network_name]
  memory_limit = 8192  # 8GB if you need more memory
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.crawl4ai.service_definition,
    # Other service definitions
  ]
}
```
