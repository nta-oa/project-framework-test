# ======================================================================================== #
#    _____                  __                 _____    _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   |_   _| _(_)__ _ __ _ ___ _ _ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \    | || '_| / _` / _` / -_) '_(_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|   |_||_| |_\__, \__, \___|_| /__/
#                                                        |___/|___/
# ======================================================================================== #

# ---------------------------------------------------------------------------------------- #
# -- < Iac Triggers > --
# ---------------------------------------------------------------------------------------- #
#  -- trigger invoked to validate PULL REQUEST on the global IAC
resource "google_cloudbuild_trigger" "iac-pullrequest-trigger" {
  for_each    = local.pr_triggers
  provider    = google-beta
  project     = local.triggers_env_conf[each.key].project
  name        = "${local.app_name_short}-trigger-iac-pr-${each.key}"
  description = "Plan the main IaC in ${each.key}. Trigger invoked by a pull request in branch ${each.value.branch}."

  github {
    owner = local.owner
    name  = local.repository_name
    pull_request {
      branch = "^${each.value.branch}$"
    }
  }

  build {
    step {
      id         = "check files"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "gsutil cat gs://${local.deploy_bucket}/checks/files.md5 | md5sum -c -"
      ]
    }

    step {
      id         = "IaC terraform plan on ${each.key}"
      name       = "gcr.io/itg-btdpshared-gbl-ww-pd/generic-build-front"
      entrypoint = "make"
      args = [
        "ENV=${each.key}",
        "iac-plan"
      ]
    }

    tags    = ["pull-request", local.repository_name]
    timeout = "${local.trigger_timeout}s"
  }

  # modification in this directory will invoke the trigger
  included_files = ["iac/**"]
}


#  -- trigger invoked when MERGING change for the global IAC
resource "google_cloudbuild_trigger" "iac-deploy-trigger" {
  for_each    = local.triggers_env
  provider    = google-beta
  project     = local.triggers_env_conf[each.key].project
  name        = "${local.app_name_short}-trigger-iac-deploy-${each.key}"
  description = "Deploy the main IaC in ${each.key}. Trigger invoked by a merge in branch ${each.value.branch}."
  disabled    = lookup(each.value, "disabled", false)

  github {
    owner = local.owner
    name  = local.repository_name
    push {
      branch = "^${each.value.branch}$"
    }
  }

  build {

    step {
      id         = "check files"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "gsutil cat gs://${local.deploy_bucket}/checks/files.md5 | md5sum -c -"
      ]
    }

    step {
      id         = "deploy ${each.key}"
      name       = "gcr.io/itg-btdpshared-gbl-ww-pd/generic-build-front"
      entrypoint = "make"
      args = [
        "ENV=${each.key}",
        "iac-deploy",
      ]
    }

    dynamic "step" {
      for_each = toset(lookup(each.value, "next", "") != "" ? [each.value.next] : [])
      content {
        id   = "goto ${each.value.next}"
        name = "gcr.io/cloud-builders/gcloud"
        args = [
          "beta",
          "builds",
          "triggers",
          "run",
          "${local.app_name_short}-trigger-iac-deploy-${each.value.next}",
          "--project",
          lookup(local.triggers_env_conf, each.value.next, null).project,
          "--branch",
          each.value.branch
        ]
      }
    }

    tags    = ["deploy-iac", local.repository_name]
    timeout = "${local.trigger_timeout}s"
  }
  # modification in this directory will invoke the trigger
  included_files = ["iac/**"]
}
