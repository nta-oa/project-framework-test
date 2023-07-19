# ======================================================================================== #
#    _____                  __                          _ ___     _           _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    _ __  __| | __| __| |_  ___ __| |__ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | '  \/ _` |__ \/ _| ' \/ -_) _| / /(_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_| |_|_|_\__,_|___/\__|_||_\___\__|_\_\/__/
#
# ======================================================================================== #
resource "null_resource" "md5checks" {
  provider = null
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
cd ../.. && md5sum $(ls ${var.protected_files} 2>/dev/null || echo -n "") | \
gsutil cp - gs://${local.deploy_bucket}/checks/files.md5
EOT
  }
}

/**
 * Gives access to the cloud build GCB to read bucket objects.
 */
resource "google_storage_bucket_iam_member" "deploy_readers" {
  provider = google-beta
  for_each = local.triggers_env
  bucket   = local.deploy_bucket
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${data.google_project.env_projects[each.key].number}@cloudbuild.gserviceaccount.com"
}
