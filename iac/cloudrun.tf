# ======================================================================================== #
#    _____                  __                __      __       _   _              _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   \ \    / /__ _ _| |_| |___  __ _ __| |
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \   \ \/\/ / _ \ '_| / / / _ \/ _` / _` |
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|   \_/\_/\___/_| |_\_\_\___/\__,_\__,_|
#
# ======================================================================================== #

resource "google_cloud_run_service" "default" {
  provider = google-beta
  name     = local.service_name
  location = local.region

  template {
    spec {
      containers {
        image = "gcr.io/${local.docker_repo}/${local.app_name}:${local.revision}"

        env {
          name  = "NODE_ENV"
          value = "production"
        }
        env {
          name  = "TS_NODE_BASEURL"
          value = "./build"
        }
        env {
          name  = "PROJECT"
          value = local.project
        }
        env {
          name  = "PROJECT_ENV"
          value = local.project_env
        }
        env {
          name  = "PROJECT_DATA"
          value = local.project_data
        }
        env {
          name  = "REDIS_HOST"
          value = google_redis_instance.data.host
        }
        env {
          name  = "REDIS_PORT"
          value = google_redis_instance.data.port
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "1024Mi"
          }
        }
      }
      service_account_name  = google_service_account.default.email
      container_concurrency = local.concurrency
      timeout_seconds       = local.timeout
    }


    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = "1000"
        "run.googleapis.com/cpu-throttling"       = true
        "run.googleapis.com/startup-cpu-boost"    = true
        "run.googleapis.com/vpc-access-egress"    = "all-traffic"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
      }

      labels = {
        env     = local.project_env
        project = local.project
        name    = local.app_name
      }
    }
  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }

  autogenerate_revision_name = true
  traffic {
    percent         = 100
    latest_revision = true
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      template[0].metadata[0].labels
    ]
  }
  depends_on = [
    google_redis_instance.data
  ]
}
