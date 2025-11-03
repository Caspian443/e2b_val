job "api" {
  datacenters = ["e2b-dc"]
  node_pool = "api"
  priority = 90

  group "api-service" {
    count = 1

    restart {
      interval = "5s"
      attempts = 1
      delay    = "5s"
      mode     = "delay"
    }

    network {
      port "api" {
        static = 3000
      }
    }

    service {
      name = "api"
      port = "api"
      task = "start"

      check {
        type     = "http"
        name     = "health"
        path     = "/health"
        interval = "10s"
        timeout  = "3s"
        port     = "api"
      }
    }

    task "db-migrator" {
      driver = "docker"

      env {
        POSTGRES_CONNECTION_STRING = "postgresql://e2b:Galaxy123@192.168.0.183:5432/e2b-dev?sslmode=disable"
      }

      config {
        image = "mp-bp-cn-shanghai.cr.volces.com/e2b/db-migrator:latest"
        dns_servers = ["8.8.8.8", "223.5.5.5"]
      }

      resources {
        cpu    = 250
        memory = 128
      }

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
    }

    task "start" {
      driver       = "docker"
      kill_timeout = "30s"
      kill_signal  = "SIGTERM"

      resources {
        memory = 2048
        cpu    = 2000
      }

      env {
        NODE_ID                        = "ac2ddb2a"
        ORCHESTRATOR_PORT              = "9090"
        ORCHESTRATOR_HOST              = "192.168.0.178"
        TEMPLATE_MANAGER_HOST          = "192.168.0.180:9093"

        POSTGRES_CONNECTION_STRING     = "postgresql://e2b:Galaxy123@192.168.0.183:5432/e2b-dev?sslmode=disable"
        SUPABASE_JWT_SECRETS           = "e2b-dev-jwt-secret-change-in-production"
        CLICKHOUSE_CONNECTION_STRING   = "http://clickhouse.service.consul:8123"

        REDIS_URL                      = "192.168.0.182:6379"
        REDIS_CLUSTER_URL              = ""

        ENVIRONMENT                    = "dev"
        ADMIN_TOKEN                    = "dev-admin-token-change-in-production"
        SANDBOX_ACCESS_TOKEN_HASH_SEED = "dev-random-seed-change-in-production"

        NOMAD_TOKEN                    = "79fd6fb2-ef94-7b05-8eb3-7cabf872c90f"

        POSTHOG_API_KEY                = ""
        ANALYTICS_COLLECTOR_HOST       = ""
        ANALYTICS_COLLECTOR_API_TOKEN  = ""
        OTEL_TRACING_PRINT             = "false"
        LOGS_COLLECTOR_ADDRESS         = "http://localhost:8081"
        OTEL_COLLECTOR_GRPC_ENDPOINT   = "localhost:4317"

        DNS_PORT                       = "53"
        LOCAL_CLUSTER_ENDPOINT         = ""
        LOCAL_CLUSTER_TOKEN            = ""
        TEMPLATE_BUCKET_NAME           = "skip"
      }

      config {
        network_mode = "host"
        image        = "mp-bp-cn-shanghai.cr.volces.com/e2b/api:latest"
        ports        = ["api"]
        dns_servers  = ["8.8.8.8", "223.5.5.5"]
        args         = [
          "--port", "3000",
        ]
      }
    }
  }
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
