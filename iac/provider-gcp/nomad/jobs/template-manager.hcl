job "template-manager-system" {
  datacenters = ["e2b-dc"]
  type = "service"
  node_pool  = "default"
  priority = 70

# https://developer.hashicorp.com/nomad/docs/job-specification/update

  group "template-manager" {

    // Try to restart the task indefinitely
    // Tries to restart every 5 seconds
    restart {
      interval         = "5s"
      attempts         = 1
      delay            = "5s"
      mode             = "delay"
    }

    network {
      port "template-manager" {
        static = "9093"
      }
    }

    service {
      name = "template-manager"
      port = "9093"

      check {
        type         = "grpc"
        name         = "health"
        interval     = "20s"
        timeout      = "5s"
        grpc_use_tls = false
        port         = "9093"
      }
    }

    task "start" {
      driver = "raw_exec"

     kill_timeout      = "10m"

      kill_signal  = "SIGTERM"

      resources {
        memory     = 10240
        cpu        = 256
      }

      env {
        NODE_ID                       = "43cd2f53"
        CONSUL_TOKEN                  = "d0ba2421-2e78-a365-13d7-14110c2e1990"
        API_SECRET                    = ""
        OTEL_TRACING_PRINT            = "false"
        ENVIRONMENT                   = "dev"
        PROXY_PORT                    = "9091"
        TEMPLATE_BUCKET_NAME          = "skip"
        STORAGE_PROVIDER              = "Local"
        BUILD_CACHE_BUCKET_NAME       = ""
        OTEL_COLLECTOR_GRPC_ENDPOINT  = "localhost:4317"
        LOGS_COLLECTOR_ADDRESS        = "http://localhost:8081"
        ORCHESTRATOR_SERVICES         = "template-manager"
        SHARED_CHUNK_CACHE_PATH       = ""
        CLICKHOUSE_CONNECTION_STRING  = "http://clickhouse.service.consul:8123"
        DOCKERHUB_REMOTE_REPOSITORY_URL  = ""
        ARTIFACTS_REGISTRY_PROVIDER   = "Local"
        GRPC_PORT                     = "9093"
        GIN_MODE                      = "release"

      }

      config {
        command = "/opt/template-manager/template-manager"
      }
    }
  }
}