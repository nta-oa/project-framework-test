
resource "google_compute_network" "vpc" {
  provider                = google-beta
  name                    = "${local.app_name_short}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "data" {
  provider                 = google-beta
  name                     = "${local.app_name_short}-data-subnet-${local.multiregion}-${local.project_env}"
  ip_cidr_range            = "10.1.0.0/28"
  region                   = local.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}
