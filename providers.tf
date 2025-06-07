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
    dotenv = {
      source  = "germanbrew/dotenv"
      version = "1.2.5"
    }
  }
}

provider "cloudflare" {
  api_token = module.cloudflare_globals.cloudflare_api_token
}
