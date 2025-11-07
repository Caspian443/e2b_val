job "orchestrator-1" {
  type = "service"
  node_pool = "default"

  priority = 90

  group "client-orchestrator" {
   network {
      port "grpc" {
        static = 9090
      }
      port "proxy" {
        static = 5007
      }
    }
    service {
      name = "orchestrator"
      port = "grpc"

      check {
        type         = "grpc"
        name         = "health"
        interval     = "20s"
        timeout      = "5s"
        grpc_use_tls = false
        port         = "grpc"
      }
    }

    service {
      name = "orchestrator-proxy"
      port = "proxy"
    }

    task "start" {
      driver = "raw_exec"

      restart {
        attempts = 0
      }

      resources {
        memory     = 10240
        cpu        = 20
      }

      env {
        NODE_ID                      = "43cd2f53"
        CONSUL_TOKEN                 = "d0ba2421-2e78-a365-13d7-14110c2e1990"
        OTEL_TRACING_PRINT           = "false"
        LOGS_COLLECTOR_ADDRESS       = ""
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
        PROXY_PORT                   = "5007"
        GIN_MODE                     = "release"
        LAUNCH_DARKLY_API_KEY         = ""
        SANDBOX_HYPERLOOP_PROXY_PORT = "5011"

      }

      config {
        command = "/opt/orchestrator/orchestrator"
      }
    }
  }
}