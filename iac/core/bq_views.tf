# ======================================================================================== #
#   __   ___
#   \ \ / (_)_____ __ _____
#    \ V /| / -_) V  V (_-<
#     \_/ |_\___|\_/\_//__/
#
# ======================================================================================== #

locals {
  #look for Views config yaml file
  tpl_views = fileset("${local.configuration_folder}/views/", "**/*.yaml")
  config_views = [
    for view in local.tpl_views : merge(
      {
        file_path      = view
        file_stem_path = trimsuffix(view, ".yaml")
        file_stem      = basename(trimsuffix(view, ".yaml"))
      },
      yamldecode(
        templatefile(
          "${local.configuration_folder}/views/${view}",
          merge(
            local.template_vars,
            {
              datasets = local.dataset_map
              tables   = local.tables
              udfs     = local.udf_map
            }
          )
        )
      )
    )
  ]

  #look for materialized views yaml file
  materialized_views = fileset("${local.configuration_folder}/matviews/", "**/*.yaml")
  config_mviews = [
    for view in local.materialized_views : merge(
      {
        file_path      = view
        file_stem_path = trimsuffix(view, ".yaml")
        file_stem      = basename(trimsuffix(view, ".yaml"))
      },
      yamldecode(
        templatefile(
          "${local.configuration_folder}/matviews/${view}",
          merge(
            local.template_vars,
            {
              datasets = local.dataset_map
              tables   = local.tables
              udfs     = local.udf_map
            }
          )
        )
      )
    )
  ]

  #Read config from views yaml file and create only if dataset exist
  view_output = [
    for view in local.config_views : {
      file_stem_path         = view.file_stem_path
      dataset_id             = local.dataset_map[lookup(view, "dataset", lookup(view, "dataset_id", null))].dataset_id
      view_id                = "${view.view_id}_v${view.version}"
      query                  = view.query
      description            = view.description
      project                = local.dataset_map[lookup(view, "dataset", lookup(view, "dataset_id", null))].project
      level                  = view.level
      authorized_on_datasets = coalesce(lookup(view, "authorized_on_datasets", null), [])
    }
  ]

  /* We have defined view level dependency in this code.
    This information is provided in views configuration file through mandatory field "level".

    If there is no dependency on another view, then the level must be 0.
    If there is one dependency on another view, then the level must be 1.
    Currently this framework cannot handle a number of dependecies higher than 1.
  */
  view_map = {
    for view in local.view_output : view.file_stem_path => merge(
      view,
      { reference = "${view.project}.${view.dataset_id}.${view.view_id}" }
    )
  }
  views_level_0 = { for k, v in local.view_map : k => v if v.level == 0 }
  views_level_1 = { for k, v in local.view_map : k => v if v.level == 1 }

  view_dataset_accesses = merge([
    for view in local.view_output : {
      for dataset in view.authorized_on_datasets :
      "${view.file_stem_path}_${dataset}" => {
        project    = local.dataset_map[dataset].project
        dataset_id = local.dataset_map[dataset].dataset_id
        view       = view
      }
    }
  ]...)

  #Read config for materialized view from yaml file and create only if dataset exist.
  mview_output = [
    for mview in local.config_mviews : {
      file_stem_path      = mview.file_stem_path
      dataset_id          = local.dataset_map[lookup(mview, "dataset", lookup(mview, "dataset_id", null))].dataset_id
      table_id            = "${mview.view_id}_v${mview.version}"
      query               = mview.query
      description         = mview.description
      enable_refresh      = mview.enableRefresh
      refresh_interval_ms = lookup(mview, "refreshIntervalMs", "3600000")
      range_partitioning  = lookup(mview, "range_partitioning", null)
      time_partitioning   = lookup(mview, "time_partitioning", null)
      clustering          = lookup(mview, "clustering", null)
      project             = local.dataset_map[lookup(mview, "dataset", lookup(mview, "dataset_id", null))].project
    }
  ]

  mview_map = {
    for view in local.mview_output : view.file_stem_path => {
      reference  = "${view.project}.${view.dataset_id}.${view.table_id}"
      project    = view.project
      dataset_id = view.dataset_id
      table_id   = view.table_id
    }
  }
}

resource "google_bigquery_table" "materialized_views" {

  for_each = {
    for view in local.mview_output : view.file_stem_path => view
  }

  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.table_id
  clustering          = each.value.clustering
  description         = each.value.description
  deletion_protection = false

  dynamic "range_partitioning" {
    for_each = each.value.range_partitioning != null ? [1] : []
    content {
      field = each.value.range_partitioning.field
      range {
        start    = each.value.range_partitioning.start
        end      = each.value.range_partitioning.end
        interval = each.value.range_partitioning.interval
      }
    }
  }

  dynamic "time_partitioning" {
    for_each = each.value.time_partitioning != null ? [1] : []
    content {
      type                     = each.value.time_partitioning.type
      field                    = each.value.time_partitioning.field
      require_partition_filter = lookup(each.value.time_partitioning, "require_partition_filter", null)
    }
  }

  materialized_view {
    query               = each.value.query
    enable_refresh      = each.value.enable_refresh
    refresh_interval_ms = each.value.refresh_interval_ms
  }
  depends_on = [google_bigquery_table.tables]
}

resource "google_bigquery_table" "views_level_0" {

  for_each = local.views_level_0

  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.view_id
  description         = each.value.description
  deletion_protection = false

  view {
    query          = each.value.query
    use_legacy_sql = false
  }
  depends_on = [google_bigquery_table.tables]
}

resource "google_bigquery_table" "views_level_1" {

  for_each = local.views_level_1

  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.view_id
  description         = each.value.description
  deletion_protection = false

  view {
    query          = each.value.query
    use_legacy_sql = false
  }
  depends_on = [google_bigquery_table.views_level_0]

}

resource "google_bigquery_dataset_access" "view_dataset_accesses" {
  for_each   = local.view_dataset_accesses
  dataset_id = each.value.dataset_id
  project    = each.value.project

  view {
    project_id = each.value.view.project
    dataset_id = each.value.view.dataset_id
    table_id   = each.value.view.view_id
  }
  depends_on = [google_bigquery_table.views_level_1]
}

output "bq_mviews" {
  value = google_bigquery_table.materialized_views
}

output "bq_views" {
  value = merge(
    google_bigquery_table.views_level_0,
    google_bigquery_table.views_level_1
  )
}

output "bq_view_access" {
  value = google_bigquery_dataset_access.view_dataset_accesses
}
