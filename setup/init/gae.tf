# ======================================================================================== #
#    _____                  __                  ___   _   ___
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    / __| /_\ | __|
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | (_ |/ _ \| _|
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|  \___/_/ \_\___|
#
# ======================================================================================== #
resource "google_app_engine_application" "app" {
  provider      = google
  location_id   = local.gae_location
  database_type = "CLOUD_FIRESTORE"
  depends_on    = [google_project_service.apis]
}
