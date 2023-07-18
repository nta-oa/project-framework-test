# ======================================================================================== #
#    _____                  __                 ___     _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   | _ \___| |___ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  |   / _ \ / -_|_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |_|_\___/_\___/__/
#
# ======================================================================================== #

/**
 * Defines permissions to allow promotion of build from a low environment to the one above.
 * For instance promotion from qa to np, GCB SA of qa needs to trigger builds in np.
 */
# inter-project trigger: add permissions to trigger
resource "google_project_iam_member" "inter_project" {
  for_each = { for key, val in local.triggers_env : key => val.next if lookup(val, "next", null) != null }
  project  = lookup(local.triggers_env_conf, each.value, null).project
  role     = "roles/cloudbuild.builds.editor"
  member   = "serviceAccount:${local.app_name}-sa-cloudbuild-${each.key}@${lookup(local.triggers_env_conf, each.key, null).project}.iam.gserviceaccount.com"
}

# Allow the GCB SA of the current environment to impersonate the SA in the next one
resource "google_service_account_iam_member" "act_as_next_trigger" {
  provider           = google-beta
  for_each           = local.act_as_next
  service_account_id = local.gcb_sa_id_map[each.value.next_env]
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.gcb_sa_email_map[each.value.current_env]}"
}
