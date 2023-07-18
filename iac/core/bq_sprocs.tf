# ======================================================================================== #
#    ___ _                  _   ___                    _
#   / __| |_ ___ _ _ ___ __| | | _ \_ _ ___  __ ___ __| |_  _ _ _ ___ ___
#   \__ \  _/ _ \ '_/ -_) _` | |  _/ '_/ _ \/ _/ -_) _` | || | '_/ -_|_-<
#   |___/\__\___/_| \___\__,_| |_| |_| \___/\__\___\__,_|\_,_|_| \___/__/
#
# ======================================================================================== #

locals {
  sprocs_directory = "${local.configuration_folder}/sql-scripts/sprocs"
  sproc_files      = fileset(local.sprocs_directory, "**/*.yaml")
  sproc_sql_files  = fileset(local.sprocs_directory, "**/*.sql")

  sproc_configurations = {
    for file_path in local.sproc_files :
    trimsuffix(file_path, ".yaml") => merge(
      {
        file_path      = file_path
        file_stem_path = trimsuffix(file_path, ".yaml")
        file_stem      = basename(trimsuffix(file_path, ".yaml"))
      },
      yamldecode(
        templatefile(
          "${local.sprocs_directory}/${file_path}",
          merge(local.template_vars, {
            datasets = local.dataset_map
            views    = local.view_map
            tables   = local.tables
            mviews   = local.mview_map
          })
        )
      )
    )
  }

  sproc_sql = {
    for file_path in local.sproc_sql_files :
    trimsuffix(file_path, ".sql") => templatefile(
      "${local.sprocs_directory}/${file_path}",
      merge(local.template_vars, {
        datasets = local.dataset_map
        views    = local.view_map
        tables   = local.tables
        mviews   = local.mview_map
      })
    )
  }

  sproc_map = {
    for sproc, content in local.sproc_configurations :
    sproc => {
      reference  = "${local.dataset_map[lookup(content, "dataset", lookup(content, "dataset_id", null))].reference}.${content.routine_id}"
      project    = local.dataset_map[lookup(content, "dataset", lookup(content, "dataset_id", null))].project
      dataset_id = local.dataset_map[lookup(content, "dataset", lookup(content, "dataset_id", null))].dataset_id
      routine_id = content.routine_id
    }
  }
}

resource "google_bigquery_routine" "stored_procedure" {
  provider        = google
  for_each        = local.sproc_configurations
  project         = local.dataset_map[lookup(each.value, "dataset", lookup(each.value, "dataset_id", null))].project
  dataset_id      = local.dataset_map[lookup(each.value, "dataset", lookup(each.value, "dataset_id", null))].dataset_id
  routine_id      = each.value.routine_id
  routine_type    = "PROCEDURE"
  description     = lookup(each.value, "description", null)
  language        = lookup(each.value, "language", "SQL")
  definition_body = lookup(each.value, "definition_body", lookup(local.sproc_sql, each.key, "") == "" ? "" : "BEGIN\n${lookup(local.sproc_sql, each.key, "")}\nEND")

  dynamic "arguments" {
    for_each = lookup(each.value, "arguments", [])

    content {
      name          = arguments.value.name
      argument_kind = lookup(arguments.value, "argument_kind", null)
      data_type     = arguments.value.data_type
      mode          = lookup(arguments.value, "mode", null)
    }
  }

  depends_on = [
    google_bigquery_dataset.datasets,
    google_bigquery_table.tables,
    google_bigquery_routine.user_defined_function
  ]

}

output "bq_sprocs" {
  value = google_bigquery_routine.stored_procedure
}
