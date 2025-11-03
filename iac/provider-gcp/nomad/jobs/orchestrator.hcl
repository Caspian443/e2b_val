job "orchestrator-1" {
  type = "system"
  node_pool = "default"

  priority = 90

  group "client-orchestrator" {
    service {
      name = "orchestrator"
      port = "9090"

      check {
        type         = "grpc"
        name         = "health"
        interval     = "20s"
        timeout      = "5s"
        grpc_use_tls = false
        port         = "9090"
      }
    }

    service {
      name = "orchestrator-proxy"
      port = "9091"
    }

    task "start" {
      driver = "raw_exec"

      restart {
        attempts = 0
      }

      env {
        NODE_ID                      = "$${node.unique.name}"
        CONSUL_TOKEN                 = "d0ba2421-2e78-a365-13d7-14110c2e1990"
        OTEL_TRACING_PRINT           = "false"
        LOGS_COLLECTOR_ADDRESS       = "http://localhost:8081"
        ENVIRONMENT                  = "dev"
        ENVD_TIMEOUT                 = ""
        TEMPLATE_BUCKET_NAME         = "skip"
        STORAGE_PROVIDER = "Local"
        OTEL_COLLECTOR_GRPC_ENDPOINT = "localhost:4317"
        ALLOW_SANDBOX_INTERNET       = ""
        SHARED_CHUNK_CACHE_PATH      = ""
        CLICKHOUSE_CONNECTION_STRING = ""
        REDIS_URL                    = "192.168.0.182:6379"
        REDIS_CLUSTER_URL            = ""
        GRPC_PORT                    = "9090"
        PROXY_PORT                   = "9091"
        GIN_MODE                     = "release"
        LAUNCH_DARKLY_API_KEY         = ""

      }

      config {
        command = "/e2b-ebm/infra/packages/orchestrator/bin/orchestrator"
      }
    }
  }
}
