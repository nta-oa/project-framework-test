# DNS
resource "google_dns_managed_zone" "default" {
  provider = google
  project  = local.project
  name     = "oa-c-fr"
  dns_name = "${local.domain}."
}

resource "google_dns_record_set" "frontend" {
  name = "${local.sub-domain}.${google_dns_managed_zone.default.dns_name}"
  type = "A"
  ttl  = 60

  managed_zone = google_dns_managed_zone.default.name

  rrdatas = [google_compute_global_forwarding_rule.default.ip_address]
}
