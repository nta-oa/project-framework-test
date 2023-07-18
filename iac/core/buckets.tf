# ======================================================================================== #
#    ___         _       _
#   | _ )_  _ __| |_____| |_ ___
#   | _ \ || / _| / / -_)  _(_-<
#   |___/\_,_\__|_\_\___|\__/__/
#
# ======================================================================================== #

locals {
  buckets_folder = "${local.configuration_folder}/buckets"

  bucket_raw_configs = {
    for file_path in fileset(local.buckets_folder, "**/*.yaml") :
    trimsuffix(file_path, ".yaml") => merge(
      {
        file_path      = file_path
        file_stem_path = trimsuffix(file_path, ".yaml")
        file_stem      = basename(trimsuffix(file_path, ".yaml"))
      },
      yamldecode(
        templatefile(
          "${local.buckets_folder}/${file_path}",
          local.template_vars
        )
      )
    )
  }
  bucket_configs = {
    for file_stem_path, conf in local.bucket_raw_configs :
    file_stem_path => {
      file_stem          = conf.file_stem
      location           = lookup(conf, "location", "EU")
      expiration_in_days = lookup(conf, "expiration_in_days", null)
      notification       = lookup(conf, "notification", null)
      use_flows          = lookup(conf, "use_flows", false)
    }
  }

  # Create a map of bucket with elements to stay consistent with the other resources
  bucket_map = ({
    for file_stem_path, bucket in local.bucket_configs :
    file_stem_path => merge(
      bucket,
      { reference = "${local.app_name_short}-gcs-${bucket.file_stem}-${lower(bucket.location)}-${local.project_env}" }
    )
  })

  bucket_notification_configs = local.is_sbx ? {} : {
    for file_stem_path, conf in local.bucket_configs :
    file_stem_path => {
      topic_name         = conf.notification["topic_name"]
      topic_project      = lookup(conf.notification, "topic_project", local.project)
      object_name_prefix = lookup(conf.notification, "object_name_prefix", null)
    }
    if lookup(conf, "notification", null) != null
  }

  bucket_using_flows = local.is_sbx ? [] : [
    for file_stem_path, conf in local.bucket_configs : file_stem_path if conf.use_flows
  ]
}


resource "google_storage_bucket" "buckets" {
  for_each = local.bucket_configs
  project  = local.project
  name     = "${local.app_name_short}-gcs-${each.value.file_stem}-${lower(each.value.location)}-${local.project_env}"
  location = each.value.location

  uniform_bucket_level_access = true
  force_destroy               = true # destroy when removed even if not empty

  dynamic "lifecycle_rule" {
    for_each = each.value.expiration_in_days == null ? [] : [each.value.expiration_in_days]
    content {
      condition {
        age = each.value.expiration_in_days
      }
      action {
        type = "Delete"
      }
    }
  }
}

# Notifications for buckets go through config interface
resource "restapi_object" "bucket_notifications_topic_arrival" {
  provider = restapi.configinterface

  for_each     = toset(local.bucket_using_flows)
  path         = "/v1/projects/${local.project}/buckets/${google_storage_bucket.buckets[each.value].name}/notifications"
  id_attribute = "data/notification_id"
  data = jsonencode({
    topic_path     = "projects/itg-btdpback-gbl-ww-pd/topics/btdp-topic-arrival-pd"
    payload_format = "JSON_API_V1"
  })
  debug = true

  depends_on = [
    restapi_object.configinterface_project
  ]
}

# Notifications for buckets going through standard GCP pub/sub.
resource "google_storage_notification" "notifications" {
  for_each           = local.bucket_notification_configs
  bucket             = google_storage_bucket.buckets[each.key].name
  topic              = "projects/${each.value.topic_project}/topics/${each.value.topic_name}"
  payload_format     = "JSON_API_V1"
  object_name_prefix = each.value.object_name_prefix

  depends_on = [google_storage_bucket.buckets]
}

output "buckets" {
  value = google_storage_bucket.buckets
}

output "bucket_notifications_topic_arrival" {
  value = restapi_object.bucket_notifications_topic_arrival
}
