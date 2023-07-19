# ======================================================================================== #
#    _____                  __                 ___   _   __  __
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   |_ _| /_\ |  \/  |
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \   | | / _ \| |\/| |
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |___/_/ \_\_|  |_|
#
# ======================================================================================== #
# To provide permissions to this module service account

locals {
  self_roles = toset([
    "run.invoker"
  ])
  act_as_itself_roles = toset([
    "iam.serviceAccountUser",
    "iam.serviceAccountTokenCreator",
  ])
  roles = toset([
    "logging.logWriter",
    "errorreporting.writer",
    "bigquery.dataViewer",
    "bigquery.jobUser",
    "datastore.user",
  ])
}

# -- main service account
resource "google_service_account" "default" {
  provider     = google-beta
  account_id   = "${local.app_name_short}-sa-${local.project_env}"
  display_name = "Main identity for ${local.app_name_short} service"
}

# -- self-invocation
# Ensure the service account can invoke itself
resource "google_cloud_run_service_iam_member" "self_invoker" {
  for_each = local.self_roles
  provider = google-beta
  location = local.region
  service  = google_cloud_run_service.default.name
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.default.email}"
}

# Additional permissions to act as itself with other Google services
resource "google_service_account_iam_member" "act_as_itself" {
  for_each           = local.act_as_itself_roles
  provider           = google-beta
  service_account_id = google_service_account.default.name
  role               = "roles/${each.key}"
  member             = "serviceAccount:${google_service_account.default.email}"
}

# -- Global project permissions
resource "google_project_iam_member" "permissions" {
  for_each = local.roles
  provider = google-beta
  project  = local.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.default.email}"
}
