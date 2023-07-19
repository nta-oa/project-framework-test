# Cloud Armor

resource "google_recaptcha_enterprise_key" "primary" {
  project      = local.project
  display_name = "${local.app_name_short}-recaptcha-webapp-${local.project_env}"

  web_settings {
    integration_type  = "SCORE"
    allow_all_domains = true
  }

  depends_on = [google_project_service.apis]
}

resource "google_compute_security_policy" "policy" {
  provider    = google-beta
  name        = "${local.app_name_short}-cloudarmorpolicy-webapp-${local.project_env}"
  description = "basic security policy"
  type        = "CLOUD_ARMOR"

  recaptcha_options_config {
    redirect_site_key = google_recaptcha_enterprise_key.primary.name
  }

  rule {
    action   = "throttle"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Throttle policy"

    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "redirect"

      enforce_on_key = ""

      enforce_on_key_configs {
        enforce_on_key_type = "IP"
      }
      exceed_redirect_options {
        type = "GOOGLE_RECAPTCHA"
      }

      rate_limit_threshold {
        count        = 3
        interval_sec = 30
      }
    }
  }
}
