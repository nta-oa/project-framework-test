locals {
  apis = toset([
    "certificatemanager",
    "recaptchaenterprise",
  ])
}

resource "google_project_service" "apis" {
  provider           = google
  for_each           = local.apis
  service            = "${each.key}.googleapis.com"
  disable_on_destroy = false
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta
  name     = "${local.app_name_short}-sslcert-default-${local.project_env}"

  managed {
    domains = [local.full_url]
  }
}

# Load Balancing
resource "google_compute_url_map" "default" {
  project     = local.project
  name        = "url-map"
  description = "a description"

  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_https_proxy" "default" {
  provider = google-beta
  name     = "${local.app_name_short}-targethttpsproxy-test-${local.project_env}"
  url_map  = google_compute_url_map.default.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.name
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.default
  ]
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-rule"
  target     = google_compute_target_https_proxy.default.self_link
  port_range = "443"
}

