job "client-proxy" {
  datacenters = ["e2b-dc"]
  type        = "service"
  node_pool   = "api"
  priority    = 80

  group "client-proxy" {
    count = 1

    restart {
      attempts = 2
      interval = "10m"
      delay    = "10s"
      mode     = "fail"
    }

    network {
      port "edge-api" {
        static = 3001  # Service Discovery API 端口
      }
      port "proxy" {
        static = 3002  # Proxy 端口
      }
    }

    service {
      name = "edge-api"
      port = "edge-api"

      check {
        type     = "http"
        name     = "health"
        path     = "/health"
        interval = "10s"
        timeout  = "3s"
        port     = "edge-api"
      }
    }

    service {
      name = "proxy"
      port = "proxy"

      check {
        type     = "http"
        name     = "health"
        path     = "/health/traffic"
        interval = "10s"
        timeout  = "3s"
        port     = "edge-api"
      }
    }

    task "start" {
      driver = "docker"

      resources {
        memory = 512
        cpu    = 500
      }

      env {
        NODE_ID = "${node.unique.id}"
        NODE_IP = "${attr.unique.network.ip-address}"

        EDGE_PORT         = "3001"
        EDGE_SECRET       = "local-token"
        PROXY_PORT        = "3002"
        ORCHESTRATOR_PORT = "9093"

        SD_ORCHESTRATOR_PROVIDER         = "NOMAD"
        SD_ORCHESTRATOR_NOMAD_ENDPOINT   = "http://localhost:4646"
        SD_ORCHESTRATOR_NOMAD_TOKEN      = "79fd6fb2-ef94-7b05-8eb3-7cabf872c90f"
        SD_ORCHESTRATOR_NOMAD_JOB_PREFIX = "template-manager"

        SD_EDGE_PROVIDER             = "NOMAD"
        SD_EDGE_NOMAD_ENDPOINT       = "http://localhost:4646"
        SD_EDGE_NOMAD_TOKEN          = "79fd6fb2-ef94-7b05-8eb3-7cabf872c90f"
        SD_EDGE_NOMAD_JOB_PREFIX     = "client-proxy"

        ENVIRONMENT = "dev"

        REDIS_URL         = "192.168.0.182:6379"
        REDIS_CLUSTER_URL = ""

        OTEL_COLLECTOR_GRPC_ENDPOINT = "localhost:4317"
        LOGS_COLLECTOR_ADDRESS       = "http://localhost:8081"
        LOKI_URL                     = ""
      }

      config {
        network_mode = "host"
        image        = "mp-bp-cn-shanghai.cr.volces.com/e2b/client-proxy:latest"
        ports        = ["edge-api", "proxy"]
        dns_servers  = ["8.8.8.8", "223.5.5.5"]
      }
    }
  }
}
