# ======================================================================================== #
#    _____                  __                 _____    _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   |_   _| _(_)__ _ __ _ ___ _ _ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \    | || '_| / _` / _` / -_) '_(_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|   |_||_| |_\__, \__, \___|_| /__/
#                                                        |___/|___/
# ======================================================================================== #

# ---------------------------------------------------------------------------------------- #
# -- < GCR Application Triggers > --
# ---------------------------------------------------------------------------------------- #
#  -- trigger invoked to validate PULL REQUEST on the application
resource "google_cloudbuild_trigger" "gcr-pullrequest-trigger" {
  for_each    = local.pr_triggers
  provider    = google-beta
  project     = local.triggers_env_conf[each.key].project
  name        = "${local.app_name_short}-trigger-gae-pr-${each.key}"
  description = "Plan the GCR in ${each.key}. Trigger invoked by a pull request in branch ${each.value.branch}."

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
      id         = "app validate build and test on ${each.key}"
      name       = local.generic_build_image
      entrypoint = "make"
      args = [
        "ENV=${each.key}",
        "validate",
        "build",
        "test"
      ]
    }

    options {
      machine_type = "E2_HIGHCPU_8"
    }

    tags    = ["pull-request", local.repository_name]
    timeout = "${local.trigger_timeout}s"
  }

  # modification in this directory will invoke the trigger
  included_files = [
    "package.json",
    "app/**",
    "bootstrap/**",
    "config/**",
    "sql/**",
    "tests/**"
  ]
}


#  -- trigger invoked when MERGING change for application
resource "google_cloudbuild_trigger" "gcr-deploy-trigger" {
  for_each    = local.triggers_env
  provider    = google-beta
  project     = local.triggers_env_conf[each.key].project
  name        = "${local.app_name_short}-trigger-gae-deploy-${each.key}"
  description = "Deploy the main GAE in ${each.key}. Trigger invoked by a merge in branch ${each.value.branch}."
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
      name       = local.generic_build_image
      entrypoint = "make"
      args = [
        "ENV=${each.key}",
        "build",
        "deploy",
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

    options {
      machine_type = "E2_HIGHCPU_8"
    }

    tags    = ["deploy-gcr", local.repository_name]
    timeout = "${local.trigger_timeout}s"
  }
  # modification in this directory will invoke the trigger
  included_files = [
    "package.json",
    "app/**",
    "bootstrap/**",
    "config/**",
    "sql/**",
    "tests/**"
  ]
  ignored_files = ["**/README.md"]
}
