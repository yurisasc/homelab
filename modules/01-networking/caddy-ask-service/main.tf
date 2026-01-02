terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  container_name = var.container_name != "" ? var.container_name : "caddy-ask"
  internal_port  = 8080

  # Simple Python HTTP server script for ask endpoint
  ask_server = <<-EOT
    #!/usr/bin/env python3
    from http.server import HTTPServer, BaseHTTPRequestHandler
    from urllib.parse import urlparse, parse_qs
    import os

    ALLOWLIST_FILE = "/data/allowed-domains.txt"

    class AskHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            query = parse_qs(urlparse(self.path).query)
            domain = query.get("domain", [None])[0]
            
            if not domain:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Missing domain parameter")
                return
            
            if not os.path.exists(ALLOWLIST_FILE):
                self.send_response(403)
                self.end_headers()
                self.wfile.write(b"Allowlist not found")
                return
            
            with open(ALLOWLIST_FILE) as f:
                allowed = [line.strip() for line in f if line.strip() and not line.startswith("#")]
            
            if domain in allowed:
                self.send_response(200)
                self.end_headers()
                self.wfile.write(f"Allowed: {domain}".encode())
            else:
                self.send_response(403)
                self.end_headers()
                self.wfile.write(f"Denied: {domain}".encode())
        
        def log_message(self, format, *args):
            print(f"[ASK] {args[0]}")

    if __name__ == "__main__":
        server = HTTPServer(("0.0.0.0", 8080), AskHandler)
        print("Ask service running on port 8080...")
        server.serve_forever()
  EOT
}

# Create the Python server script
resource "local_file" "ask_server" {
  content         = local.ask_server
  filename        = "${var.volume_path}/ask-service/server.py"
  file_permission = "0755"
}

module "caddy_ask" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = "python"
  tag            = "3-alpine"

  command = ["python3", "/data/server.py"]

  volumes = [
    {
      host_path      = "${var.volume_path}/ask-service"
      container_path = "/data"
      read_only      = false
    },
    {
      host_path      = var.allowlist_path
      container_path = "/data/allowed-domains.txt"
      read_only      = true
    }
  ]

  networks   = var.networks

  depends_on = [local_file.ask_server]
}
