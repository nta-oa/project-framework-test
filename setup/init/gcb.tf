# ======================================================================================== #
#    _____                  __                  ___  ___ ___
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    / __|/ __| _ )
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | (_ | (__| _ \
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|  \___|\___|___/
#
# ======================================================================================== #

resource "google_service_account" "custom_gcb_sa" {
  provider     = google
  project      = local.project
  account_id   = "${local.app_name_short}-sa-cloudbuild-${local.project_env}"
  display_name = "Custom Cloud Build SA"
  description  = "Custom SA to manage cloud build and AAD group appendable"
}

output "cloudbuild_service_account" {
  value = google_service_account.custom_gcb_sa.email
}



# Permission for the service account to trigger build using itself
resource "google_service_account_iam_member" "custom_gcb_actasitself" {
  provider           = google
  service_account_id = google_service_account.custom_gcb_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.custom_gcb_sa.email}"
}


# Permissions for the custom GCB SA
resource "google_project_iam_member" "custom_gcb_sa_iam" {
  provider   = google
  project    = local.project
  for_each   = local.gcb_roles
  role       = "roles/${each.value}"
  member     = "serviceAccount:${google_service_account.custom_gcb_sa.email}"
  depends_on = [google_project_service.apis]
}

# custom bucket to store logs dedicated to the Custom GCB SA
resource "google_storage_bucket" "custom_gcb_log_bucket" {
  provider                    = google
  project                     = local.project
  name                        = "cloudbuild-gcs-${local.bucket_region}-${local.project}"
  location                    = local.region
  force_destroy               = false
  uniform_bucket_level_access = true
}

# give permission to the SA over the logs bucket
resource "google_storage_bucket_iam_member" "custom_gcb_bucket_access" {
  provider = google
  bucket   = google_storage_bucket.custom_gcb_log_bucket.name
  role     = "roles/storage.admin"
  member   = "serviceAccount:${google_service_account.custom_gcb_sa.email}"
}

/**
 * Permission for the devs to impersonate the Cloudbuild SA on dv only
 */
resource "google_service_account_iam_member" "custom_gcb_developer_impersonate" {
  for_each   = local.developer_group != null ? toset(local.developer_group_gcb_sa_permissions) : []

  service_account_id = google_service_account.custom_gcb_sa.name
  role               = each.value
  member             = "group:${local.developer_group}"
}

locals {
  gcb_roles = toset(split("\n", trimspace(file("resources/gcb.txt"))))
}

# manages the IAM rules for the CloudBuild service account.
resource "google_project_iam_member" "cicd_cloudbuild_iam" {
  provider   = google
  project    = local.project
  for_each   = local.gcb_roles
  role       = "roles/${each.value}"
  member     = "serviceAccount:${data.google_project.default.number}@cloudbuild.gserviceaccount.com"
  depends_on = [google_project_service.apis]
}
