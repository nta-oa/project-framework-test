# ======================================================================================== #
#    _   _               ___       __ _             _   ___             _   _
#   | | | |___ ___ _ _  |   \ ___ / _(_)_ _  ___ __| | | __|  _ _ _  __| |_(_)___ _ _  ___
#   | |_| (_-</ -_) '_| | |) / -_)  _| | ' \/ -_) _` | | _| || | ' \/ _|  _| / _ \ ' \(_-<
#    \___//__/\___|_|   |___/\___|_| |_|_||_\___\__,_| |_| \_,_|_||_\__|\__|_\___/_||_/__/
#
# ======================================================================================== #

locals {
  udf_directory = "${local.configuration_folder}/sql-scripts/udf"
  udf_files     = fileset(local.udf_directory, "**/*.yaml")

  udf_configurations = {
    for file_path in local.udf_files :
    trimsuffix(file_path, ".yaml") => merge(
      {
        file_path      = file_path
        file_stem_path = trimsuffix(file_path, ".yaml")
        file_stem      = basename(trimsuffix(file_path, ".yaml"))
      },
      yamldecode(
        templatefile(
          "${local.udf_directory}/${file_path}",
          merge(
            local.template_vars,
            {
              datasets = local.dataset_map
              tables   = local.tables
            }
          )
        )
      )
    )
  }

  udf_map = ({
    for file_stem_path, udf in local.udf_configurations :
    file_stem_path => merge(
      udf,
      {
        reference = "${local.dataset_map[lookup(udf, "dataset", lookup(udf, "dataset_id", null))].reference}.${udf.routine_id}"
      }
    )
  })
}

resource "google_bigquery_routine" "user_defined_function" {
  provider        = google
  for_each        = local.udf_configurations
  dataset_id      = local.dataset_map[lookup(each.value, "dataset", lookup(each.value, "dataset_id", null))].dataset_id
  routine_id      = each.value.routine_id
  routine_type    = "SCALAR_FUNCTION"
  description     = lookup(each.value, "description", null)
  language        = each.value.language
  definition_body = each.value.definition_body

  dynamic "arguments" {
    for_each = lookup(each.value, "arguments", [])

    content {
      name          = arguments.value.name
      argument_kind = lookup(arguments.value, "argument_kind", null)
      data_type     = arguments.value.data_type
    }
  }

  return_type = each.value.return_type

  depends_on = [google_bigquery_table.views_level_1]
}

output "bq_udf" {
  value = google_bigquery_routine.user_defined_function
}
