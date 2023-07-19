# ======================================================================================== #
#    _____                  __                 _                 _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   | |   ___  __ __ _| |___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | |__/ _ \/ _/ _` | (_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |____\___/\__\__,_|_/__/
#
# ======================================================================================== #

# -- main local variables
locals {
  app_name       = var.app_name
  app_name_short = replace(var.app_name, "-", "")
  project        = var.project
  project_env    = var.project_env
  project_data   = var.project_data
  revision       = var.revision
  env_file       = jsondecode(file(var.env_file))
}

# -- location
locals {
  zone        = lookup(local.env_file, "zone", "europe-west1-b")
  region      = lookup(local.env_file, "region", replace(local.zone, "/(.*)-[a-z]$/", "$1"))
  multiregion = lookup(local.env_file, "multiregion", regex("^europe-", local.zone) == "europe-" ? "eu" : (regex("^us-", local.zone) == "us-" ? "us" : null))
}

# -- Cloud run
locals {
  docker_repo  = "itg-coewebapp-gbl-ww-dv"
  service_name = "${local.app_name_short}-gcr-${local.multiregion}-${local.project_env}"
  concurrency  = lookup(local.env_file, "concurrency", 10)
  timeout      = lookup(local.env_file, "timeout", 1800)
}

# -- Domain
locals {
  domain = lookup(local.env_file, "domain", null)
  sub-domain = lookup(local.env_file, "sub-domain", null)
  full_url = "${local.sub-domain}.${local.domain}"
}
