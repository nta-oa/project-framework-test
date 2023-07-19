# ======================================================================================== #
#    _____                  __                   _   ___ ___ ___
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __     /_\ | _ \_ _/ __|
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \   / _ \|  _/| |\__ \
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| /_/ \_\_| |___|___/
#
# ======================================================================================== #

locals {
  apis = toset([
    "bigquery",
    "cloudbuild",
    "logging",
    "secretmanager",
    "iap",
    "vpcaccess",
    "servicenetworking"
  ])
}

resource "google_project_service" "apis" {
  provider           = google-beta
  for_each           = local.apis
  service            = "${each.key}.googleapis.com"
  disable_on_destroy = false
}
