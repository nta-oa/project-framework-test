# ======================================================================================== #
#    _____                  __                                  _    _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    _ __ _ _ _____ _(_)__| |___ _ _
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | '_ \ '_/ _ \ V / / _` / -_) '_|
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| | .__/_| \___/\_/|_\__,_\___|_|
#                                             |_|
# ======================================================================================== #
terraform {
  required_version = "~> 1.0"
  backend "gcs" {}
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0.0"
    }
    null = {
      version = "~> 3.2.0"
    }
  }
}

provider "google-beta" {}

data "google_project" "env_projects" {
  provider   = google-beta
  for_each   = toset([for key, val in local.triggers_env : key])
  project_id = lookup(local.triggers_env_conf, each.key, null).project
}
