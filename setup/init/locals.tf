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

  project      = var.project
  project_env  = var.project_env
  access_token = var.access_token

  # load the json environment configuration file
  env_file = jsondecode(file(var.env_file))
}

# -- location variables
locals {
  zone = lookup(local.env_file, "zone", "europe-west1-b")
  zone_id = lookup(
    local.env_file,
    "zone_id",
    replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-([a-z])/", "$1$2$3$4")
  )
  region = lookup(local.env_file, "region", replace(local.zone, "/(.*)-[a-z]$/", "$1"))
  region_id = lookup(
    local.env_file,
    "region_id",
    replace(local.region, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])/", "$1$2$3")
  )

  multiregion = lookup(
    local.env_file, "multiregion",
    regex("^europe-", local.region) == "europe-" ? "eu" : (regex("^us-", local.region) == "us-" ? "us" : null)
  )

  gae_location = local.region == "europe-west1" || local.region == "us-central1" ? replace(local.region, "/1/", "") : local.region
}

locals {
  # -- the list of apis to be activated
  apis = toset(split("\n", trimspace(file("resources/apis.txt"))))

  btdpback_project = lookup(
    local.env_file,
    "btdpback_project",
    contains(["dv", "qa", "np", "pd"], local.project_env) ? "itg-btdpback-gbl-ww-${local.project_env}" : local.project
  )

  # -- roles to be given to the current project GCB SA
  generic_technical_roles = ["iam.serviceAccountUser", "iam.serviceAccountTokenCreator"]

  # -- dev group variable
  developer_group = lookup(local.env_file, "developer_group", null)

  # -- permissions to give to the dev group on the cloudbuild sa
  developer_group_gcb_sa_permissions = [
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator"
  ]
  developer_group_permissions = toset(split("\n", trimspace(file("resources/developers.txt"))))
}
