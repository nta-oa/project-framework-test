# ======================================================================================== #
#   ___             _       _
#  | __|_ _____ _ _| |_    /_\  _ _ __
#  | _|\ V / -_) ' \  _|  / _ \| '_/ _|
#  |___|\_/\___|_||_\__| /_/ \_\_| \__|
#
# ======================================================================================== #

locals {
  trigger_files = fileset("${local.configuration_folder}/triggers/eventarc/", "**/*.yaml")
  triggers = {
    for file_path in local.trigger_files :
    trimsuffix(file_path, ".yaml") => merge(
      {
        file_path      = file_path
        file_stem_path = trimsuffix(file_path, ".yaml")
        file_stem      = basename(trimsuffix(file_path, ".yaml"))
      },
      yamldecode(file("${local.configuration_folder}/triggers/eventarc/${file_path}"))
    )
  }
}

resource "google_pubsub_topic" "eventarc_topics" {
  for_each = local.triggers

  name = "${local.app_name}-topic-eat_${each.value.file_stem}-${local.project_env}"
}

resource "google_eventarc_trigger" "eventarc_triggers" {
  for_each = local.triggers

  name     = "${local.app_name}-eac-${each.value.file_stem}-ew1-${local.project_env}"
  location = "europe-west1"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }

  transport {
    pubsub {
      topic = google_pubsub_topic.eventarc_topics[each.key].name
    }
  }

  destination {
    workflow = google_workflows_workflow.workflow[each.value.workflow].id
  }

  service_account = data.google_service_account.workflows_sa.id
}

resource "google_pubsub_topic_iam_member" "eventarc_transmission_permissions" {
  for_each = local.triggers

  topic  = google_pubsub_topic.eventarc_topics[each.key].name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:bdtx-sa-datatx-pd@itg-btdpdatatx-gbl-ww-pd.iam.gserviceaccount.com"
}

output "eventarc_topics" {
  value = google_pubsub_topic.eventarc_topics
}
