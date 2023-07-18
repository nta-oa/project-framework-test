# ======================================================================================== #
#    _____                  __                                  _    _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    _ __ _ _ _____ _(_)__| |___ _ _
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | '_ \ '_/ _ \ V / / _` / -_) '_|
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| | .__/_| \___/\_/|_\__,_\___|_|
#                                             |_|
# ======================================================================================== #
# backend should always be GCS. It's configured from the CLI with:
# terraform init \
#   -backend-config=bucket=$DEPLOY_BUCKET \
#   -backend-config=prefix=terraform-state/global \
#   iac;
terraform {
  backend "gcs" {}
  required_version = "~> 1.3"

  required_providers {
    google = {
      source = "google"
      version = "<=4.65.2"
    }
  }
}

provider "google" {
  project = var.project
}

# load meta data about the project
data "google_project" "default" {
  provider = google
}

# Use global state for global information.
data "terraform_remote_state" "global" {
  backend = "gcs"
  config = {
    bucket = var.deploy_bucket
    prefix = "terraform-state/global"
  }
}
