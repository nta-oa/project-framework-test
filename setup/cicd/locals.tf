# ======================================================================================== #
#    _____                  __                 _                 _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   | |   ___  __ __ _| |___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | |__/ _ \/ _/ _` | (_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |____\___/\__\__,_|_/__/
#
# ======================================================================================== #

# ---------------------------------------------------------------------------------------- #
# -- mandatory fields
# ---------------------------------------------------------------------------------------- #
locals {
  app_name       = var.app_name
  app_name_short = replace(var.app_name, "-", "")

  deploy_bucket = var.deploy_bucket

  # load the json environment configuration file
  env_file = jsondecode(file(var.env_file))
  env_dir  = dirname(var.env_file)

  # modules
  modules = compact(split(" ", trimspace(var.modules)))
}

# -- location variables
locals {
  zone      = lookup(local.env_file, "zone", "europe-west1-b")
  zone_id   = replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-([a-z])/", "$1$2$3$4")
  region    = lookup(local.env_file, "region", replace(local.zone, "/(.*)-[a-z]$/", "$1"))
  region_id = replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-[a-z]/", "$1$2$3")
  multiregion = lookup(local.env_file, "multiregion",
    regex("^europe-", local.zone) == "europe-" ? "eu" : (regex("^us-", local.zone) == "us-" ? "us" : null)
  )
}


# ---------------------------------------------------------------------------------------- #
# -- CI/CD local variables definition
# ---------------------------------------------------------------------------------------- #
locals {
  # specific CI/CD
  organization_name = lookup(local.env_file, "organization_name", "loreal-datafactory")
  repository_name   = lookup(local.env_file, "repository_name", local.app_name)
  owner             = lookup(local.env_file, "owner", "loreal-datafactory")
  trigger_timeout   = lookup(local.env_file, "gcb_trigger_timeout", "7200")

  # -- the generic builder information
  builders_project      = lookup(local.env_file, "builders_project", "itg-btdpshared-gbl-ww-pd")
  generic_build_version = local.env_file["generic_build_version"]
  generic_build_image   = "gcr.io/${local.builders_project}/generic-build:${local.generic_build_version}"

  # default CI/CD configuration when not provided
  triggers_env_default = {
    dv = {
      branch   = "develop"
      pr       = false
      disabled = true # manually deployed
    }
    qa = {
      branch   = "develop"
      pr       = true
      e2etests = true
      next     = "np"
    }
    np = {
      branch   = "develop" # "preprod" on repository with full branch separation
      pr       = false
      disabled = true # next of qa
    }
    pd = {
      branch = "master"
      pr     = true
    }
  }

  triggers_env = lookup(local.env_file, "triggers_env", local.triggers_env_default)
  triggers_env_conf = {
    for env, _ in local.triggers_env :
    env => jsondecode(file("${local.env_dir}/${env}.json"))
  }

  # list of environments for which there are pull requests enabled
  pr_envs = [for env, value in local.triggers_env : env if lookup(value, "pr", false)]

  # list of environments where e2e-tests should be run after module deployment
  e2etests_envs = [for env, value in local.triggers_env : env if lookup(value, "e2etests", false)]

  # map allowing to associate an environment with its trigger information
  pr_triggers = {
    for env, conf in local.triggers_env :
    env => {
      branch   = conf.branch
      disabled = lookup(conf, "disabled", false)
      next     = lookup(conf, "next", "")
    }
    if contains(local.pr_envs, env)
  }

  modules_triggers_env = flatten([
    for env, conf in local.triggers_env : [
      for module in local.modules : {
        env          = env
        branch       = conf.branch
        disabled     = lookup(conf, "disabled", false)
        next         = lookup(conf, "next", "")
        module       = module
        module_short = replace(regex("[a-z]+[-a-z-0-9]+", module), "-", "")
      }
    ]
  ])

  # map associating module with env to have the list of deploy triggers to be created
  modules_triggers_deploy = {
    for modules_trigger in local.modules_triggers_env :
    format("%s_%s", modules_trigger.module_short, modules_trigger.env) => modules_trigger
  }

  # map associating module with env to have the list of pull request triggers to be created
  modules_triggers_pr = {
    for key, modules_trigger in local.modules_triggers_deploy : key => modules_trigger
    if contains(local.pr_envs, modules_trigger.env)
  }
}

locals {
  bucket_region = "eu"

  # map containing the GCB SA email address for each environment
  gcb_sa_email_map = {
    for env, config in local.triggers_env_conf :
    env => "${local.app_name_short}-sa-cloudbuild-${config.project_env}@${config.project}.iam.gserviceaccount.com"
  }

  # map containing the GCB SA full identifier
  gcb_sa_id_map = {
    for env, config in local.triggers_env_conf :
    env => "projects/${config.project}/serviceAccounts/${local.gcb_sa_email_map[env]}"
  }

  # map containing the build bucket for each environment
  gcb_bucket_map = {
    for env, config in local.triggers_env_conf :
    env => "gs://cloudbuild-gcs-${local.bucket_region}-${config.project}/logs"
  }

  # maps to associate the next environment for which a build must be triggered for promotion
  act_as = { for env, item in local.triggers_env : env => item.next if lookup(item, "next", null) != null }
  act_as_next = {
    for env, item in local.triggers_env :
    env => {
      next_env    = item.next
      current_env = env
    } if lookup(item, "next", null) != null
  }
}
