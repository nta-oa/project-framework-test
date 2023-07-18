# -- templating configurations
locals {
  roles_per_member = {
    for member, conf in yamldecode(
      file("resources/core_btdp_access.yaml")
    ) : member => conf
  }

  roles_at_project_level = merge([
    for member, conf in local.roles_per_member : {
      for role in try(coalesce(lookup(conf, "project", null), []), []) : # handle empty fields
      "${member}.${role}" => {
        member = member
        role   = role
      }
    }
  ]...)
  roles_per_resource_level = {
    for level in ["buckets", "datasets", "tables", "pubsub_topics", "secrets"] :
    level => merge(flatten([
      for member, conf in local.roles_per_member : [
        for resource, roles in try(coalesce(lookup(conf, level, null), {}), {}) : # handle empty fields
        {
          for role in roles :
          "${member}.${resource}.${role}" => {
            member   = member
            resource = resource # Expected format for tables: "<dataset_id>.<table_id>"
            role     = role
          }
        }
      ]
    ])...)
  }
}

# ---------------------------------------------------------------------------------------- #
# -- < Provide external access at all levels  > --
# ---------------------------------------------------------------------------------------- #
# -- project
resource "google_project_iam_member" "authorized_on_project" {
  for_each = local.roles_at_project_level
  project  = local.project
  member   = each.value.member
  role     = "roles/${each.value.role}"
}

# -- buckets
resource "google_storage_bucket_iam_member" "authorized_on_buckets" {
  for_each = local.roles_per_resource_level["buckets"]
  bucket   = each.value.resource
  member   = each.value.member
  role     = "roles/${each.value.role}"
}

# -- datasets and tables
resource "google_bigquery_dataset_iam_member" "authorized_on_datasets" {
  for_each   = local.roles_per_resource_level["datasets"]
  project    = local.project
  dataset_id = each.value.resource
  member     = each.value.member
  role       = "roles/${each.value.role}"
}

resource "google_bigquery_table_iam_member" "authorized_on_tables" {
  for_each   = local.roles_per_resource_level["tables"]
  project    = local.project
  dataset_id = split(".", each.value.resource)[0]
  table_id   = split(".", each.value.resource)[1]
  member     = each.value.member
  role       = "roles/${each.value.role}"
}

# -- pub/sub topics
resource "google_pubsub_topic_iam_member" "authorized_on_pubsubtopics" {
  for_each = local.roles_per_resource_level["pubsub_topics"]
  project  = local.project
  topic    = each.value.resource
  member   = each.value.member
  role     = "roles/${each.value.role}"
}

# -- secrets
resource "google_secret_manager_secret_iam_member" "authorized_on_secrets" {
  for_each  = local.roles_per_resource_level["secrets"]
  project   = local.project
  secret_id = each.value.resource
  member    = each.value.member
  role      = "roles/${each.value.role}"
}

# -- Summary of authorized external members on project per level
output "project_accesses" {
  value = {
    for member in distinct([for _, iam in google_project_iam_member.authorized_on_project : iam.member]) :
    member => sort([
      for _, iam in google_project_iam_member.authorized_on_project :
      iam.role
      if iam.member == member
    ])
  }
}

output "buckets_accesses" {
  value = {
    for bucket in distinct([for _, iam in google_storage_bucket_iam_member.authorized_on_buckets : iam.bucket]) :
    bucket => {
      for member in distinct([for _, iam in google_storage_bucket_iam_member.authorized_on_buckets : iam.member if iam.bucket == bucket]) :
      member => sort([
        for _, iam in google_storage_bucket_iam_member.authorized_on_buckets :
        iam.role
        if iam.member == member && iam.bucket == bucket
      ])
    }
  }
}

output "datasets_accesses" {
  value = {
    for dataset_id in distinct([for _, iam in google_bigquery_dataset_iam_member.authorized_on_datasets : iam.dataset_id]) :
    dataset_id => {
      for member in distinct([for _, iam in google_bigquery_dataset_iam_member.authorized_on_datasets : iam.member if iam.dataset_id == dataset_id]) :
      member => sort([
        for _, iam in google_bigquery_dataset_iam_member.authorized_on_datasets :
        iam.role
        if iam.member == member && iam.dataset_id == dataset_id
      ])
    }
  }
}
output "tables_accesses" {
  value = {
    for dataset_id in distinct([for _, iam in google_bigquery_table_iam_member.authorized_on_tables : iam.dataset_id]) :
    dataset_id => {
      for table_id in distinct([for _, iam in google_bigquery_table_iam_member.authorized_on_tables : iam.table_id if iam.dataset_id == dataset_id]) :
      table_id => {
        for member in distinct([for _, iam in google_bigquery_table_iam_member.authorized_on_tables : iam.member if iam.dataset_id == dataset_id && iam.table_id == table_id]) :
        member => sort([
          for _, iam in google_bigquery_table_iam_member.authorized_on_tables :
          iam.role
          if iam.member == member && iam.dataset_id == dataset_id && iam.table_id == table_id
        ])
      }
    }
  }
}

output "pubsub_topics_accesses" {
  value = {
    for topic in distinct([for _, iam in google_pubsub_topic_iam_member.authorized_on_pubsubtopics : iam.topic]) :
    topic => {
      for member in distinct([for _, iam in google_pubsub_topic_iam_member.authorized_on_pubsubtopics : iam.member if iam.topic == topic]) :
      member => sort([
        for _, iam in google_pubsub_topic_iam_member.authorized_on_pubsubtopics :
        iam.role
        if iam.member == member && iam.topic == topic
      ])
    }
  }
}

output "secrets_accesses" {
  value = {
    for secret_id in distinct([for _, iam in google_secret_manager_secret_iam_member.authorized_on_secrets : iam.secret_id]) :
    secret_id => {
      for member in distinct([for _, iam in google_secret_manager_secret_iam_member.authorized_on_secrets : iam.member if iam.secret_id == secret_id]) :
      member => sort([
        for _, iam in google_secret_manager_secret_iam_member.authorized_on_secrets :
        iam.role
        if iam.member == member && iam.secret_id == secret_id
      ])
    }
  }
}
