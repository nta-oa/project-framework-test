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
}


locals {
  # specific CI/CD
  repository_name = lookup(local.env_file, "repository_name", local.app_name)
  owner           = lookup(local.env_file, "owner", "loreal-datafactory")
  trigger_timeout = lookup(local.env_file, "gcb_trigger_timeout", "7200")

  # -- the generic builder information
  builders_project      = lookup(local.env_file, "builders_project", "itg-btdpshared-gbl-ww-pd")
  generic_build_version = lookup(local.env_file, "generic_build_version", "node18-py3.10-tf1.3.7")
  generic_build_image   = "gcr.io/${local.builders_project}/generic-build-front:${local.generic_build_version}"

  # CI/CD local conf
  triggers_env_default = {
    dv = {
      branch   = "develop"
      disabled = true
      pr       = true
    }
    qa = {
      branch   = "develop"
      disabled = false
      pr       = true
      next     = "np"
    }
    np = {
      branch   = "develop"
      disabled = true
      pr       = false
    }
    pd = {
      branch   = "master"
      disabled = false
      pr       = true
    }
  }
  triggers_env = lookup(local.env_file, "triggers_env", local.triggers_env_default)

  triggers_env_conf = { for key, val in local.triggers_env : key => jsondecode(file("${local.env_dir}/${key}.json")) }
  pr_envs           = [for key, val in local.triggers_env : key if lookup(val, "pr", false)]
  pr_triggers = {
    for env, conf in local.triggers_env :
    env => {
      branch   = conf.branch
      disabled = lookup(conf, "disabled", false)
      next     = lookup(conf, "next", "")
    }
    if contains(local.pr_envs, env)
  }

  # roles for each project
  roles_projects = flatten([
    for env, conf in local.triggers_env_conf : [
      for role in local.roles : {
        project = conf.project,
        role    = role
        env     = env
      }
    ]
  ])
}
