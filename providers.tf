terraform {
    required_providers {
        docker = {
            source  = "kreuzwerker/docker"
            version = "~> 3.6.0"
        }
        cloudflare = {
            source  = "cloudflare/cloudflare"
            version = "~> 4.0"
        }
        random = {
            source  = "hashicorp/random"
            version = "~> 3.5.1"
        }
    }
}

provider "cloudflare" {
    api_token = var.cloudflare_api_token
}
