# IAP
resource "google_iap_brand" "project_brand" {
  support_email     = "cyrille.frouin@loreal.com" # TODO: change this
  application_title = "Cloud IAP protected Application"
  project           = local.project
}

resource "google_iap_client" "project_client" {
  display_name = "Cloud IAP client"
  brand        = google_iap_brand.project_brand.name
}

resource "google_compute_region_network_endpoint_group" "webapp" {
  provider              = google-beta
  name                  = "${local.app_name_short}-neg-webapp-${local.multiregion}-${local.project_env}"
  network_endpoint_type = "SERVERLESS"
  region                = local.region
  cloud_run {
    service = google_cloud_run_service.default.name
  }
}

locals {
  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.webapp.id
        }
      ]
      enable_cdn = false

      iap_config = {
        enable = false
      }
      log_config = {
        enable = false
      }
    }
  }
}

resource "google_compute_backend_service" "default" {
  provider = google-beta

  project = local.project
  name    = "${local.app_name_short}-backend-test-default"

  load_balancing_scheme = "EXTERNAL"

  enable_cdn = false
  dynamic "backend" {
    for_each = toset(local.backends.default["groups"])
    content {
      description = lookup(backend.value, "description", null)
      group       = lookup(backend.value, "group")

    }
  }

  security_policy = google_compute_security_policy.policy.id

  iap {
    oauth2_client_id     = google_iap_client.project_client.client_id
    oauth2_client_secret = google_iap_client.project_client.secret
  }
}

resource "google_iap_web_backend_service_iam_member" "loreal" {
  project             = local.project
  web_backend_service = google_compute_backend_service.default.name
  role                = "roles/iap.httpsResourceAccessor"
  member              = "domain:loreal.com"
}

resource "google_cloud_run_service_iam_member" "iap_invoker" {
  provider = google-beta
  location = local.region
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"
}
