# ======================================================================================== #
#    _____                  __                                  _    _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    _ __ _ _ _____ _(_)__| |___ _ _
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | '_ \ '_/ _ \ V / / _` / -_) '_|
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| | .__/_| \___/\_/|_\__,_\___|_|
#                                             |_|
# ======================================================================================== #
terraform {
  backend "gcs" {}
  required_version = "~> 1.0"
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
    }
  }
}

provider "google-beta" {
  project = local.project
  region  = local.region
}

provider "google" {
  project = local.project
  region  = local.region
}

data "google_project" "project" {
  provider   = google-beta
  project_id = local.project
}
