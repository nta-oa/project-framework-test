resource "google_compute_global_address" "service_range" {
  provider      = google-beta
  name          = "${local.app_name_short}-global-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_service_connection" {
  provider                = google-beta
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.service_range.name]
}

resource "google_vpc_access_connector" "connector" {
  provider = google-beta
  name     = "vpc-connector"
  region   = local.region
  project  = local.project
  subnet {
    name = google_compute_subnetwork.data.name
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

resource "google_redis_instance" "data" {
  provider           = google-beta
  name               = "${local.app_name_short}-redis-data-${local.multiregion}-${local.project_env}"
  region             = local.region
  tier               = "BASIC"
  memory_size_gb     = 1
  authorized_network = google_compute_network.vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
}
