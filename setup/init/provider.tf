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

provider "google-beta" {
  project = local.project
}

data "google_project" "default" {
  provider = google-beta
}

resource "null_resource" "storage_sa_creation" {
  provider = null
  provisioner "local-exec" {
    command = <<EOT
      curl -X GET -H "Authorization: Bearer ${local.access_token}" \
        "https://storage.googleapis.com/storage/v1/projects/${local.project}/serviceAccount"
    EOT
  }
  depends_on = [google_project_service.apis]
}
