# ======================================================================================== #
#    _____                  __                 ___     _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   | _ \___| |___ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  |   / _ \ / -_|_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |_|_\___/_\___/__/
#
# ======================================================================================== #
locals {
  gcb_roles = toset([
    "run.admin",
    "cloudbuild.builds.builder",
    "iam.serviceAccountUser",
    "logging.logWriter",
    "secretmanager.secretAccessor"
  ])
}

# manages the IAM rules for the CloudBuild service account.
resource "google_project_iam_member" "cicd_cloudbuild_iam" {
  provider = google-beta
  for_each = local.gcb_roles
  project  = local.project
  role     = "roles/${each.value}"
  member   = "serviceAccount:${data.google_project.default.number}@cloudbuild.gserviceaccount.com"
}
