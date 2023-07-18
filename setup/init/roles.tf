# ======================================================================================== #
#    _____                  __                 ___     _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   | _ \___| |___ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  |   / _ \ / -_|_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |_|_\___/_\___/__/
#
# ======================================================================================== #

# IAM rules for the compute service account.
resource "google_project_iam_member" "compute_permissions" {
  provider   = google
  project    = local.project
  for_each   = toset(local.generic_technical_roles)
  role       = "roles/${each.key}"
  member     = "serviceAccount:${data.google_project.default.number}-compute@developer.gserviceaccount.com"
  depends_on = [google_project_service.apis]
}

# IAM rules for GS project service account to publish in local topic
data "google_storage_project_service_account" "gcs_account" {
  provider = google
  project  = local.project
}

resource "google_project_iam_member" "gcs_account_pubsub_publisher" {
  provider   = google
  project    = local.project
  role       = "roles/pubsub.publisher"
  member     = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  depends_on = [google_project_service.apis]
}

# IAM rules for the developer group.
resource "google_project_iam_member" "developer_group_permissions" {
  for_each   = local.developer_group != null ? toset(local.developer_group_permissions) : []

  project    = local.project
  role       = "roles/${each.key}"
  member     = "group:${local.developer_group}"
  depends_on = [google_project_service.apis]
}
