# ======================================================================================== #
#    _____                  __                __      __       _    __ _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   \ \    / /__ _ _| |__/ _| |_____ __ _____
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \   \ \/\/ / _ \ '_| / /  _| / _ \ V  V (_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|   \_/\_/\___/_| |_\_\_| |_\___/\_/\_//__/
#
# ======================================================================================== #


# Creates the current project cloud workflows service account.
data "google_service_account" "workflows_sa" {
  project    = local.project
  account_id = "${local.app_name_short}-sa-workflows-${local.project_env}"
}

locals {
  # Prepares the list of workflows will be created
  workflows_file_list = fileset("${local.configuration_folder}/workflows", "**/[^.]*.yaml")
  workflows_list_raw = {
    for file_path in local.workflows_file_list :
    trimsuffix(file_path, ".yaml") => "${local.configuration_folder}/workflows/${file_path}"
  }

  # Creates the list of cloud workflows library elements.
  library_file_list = fileset("${path.module}/library/workflows", "*.yaml")
  library_list = [
    for file_path in local.library_file_list : "${path.module}/library/workflows/${file_path}"
  ]

  workflows_list = {
    for file_stem_path, file_path in local.workflows_list_raw :
    file_stem_path => join(
      "\n",
      concat(
        [templatefile(
          file_path,
          merge(
            local.template_vars,
            {
              flow_id  = "uc_${local.app_name}_${basename(file_stem_path)}_${local.project_env}",
              datasets = local.dataset_map
              views    = local.view_map
              tables   = local.tables
              mviews   = local.mview_map
              sprocs   = local.sproc_map
              udfs     = local.udf_map
            }
          )
        )],
        [
          for lib_file in local.library_list :
          templatefile(
            lib_file,
            merge(
              local.template_vars,
              {
                flow_id  = "uc_${local.app_name}_${basename(file_stem_path)}_${local.project_env}",
                datasets = local.dataset_map
                views    = local.view_map
                tables   = local.tables
                mviews   = local.mview_map
                sprocs   = local.sproc_map
                udfs     = local.udf_map
              }
            )
          )
        ]
      )
    )
  }

  # Creates a dict of deployed workflows with the filename (without extension) as keys,
  # and generated name and url as content, for use in the schedulers.
  workflows_map = {
    for file_stem_path, workflow in local.workflows_list :
    file_stem_path => {
      name = "${local.app_name_short}-wkf-${basename(file_stem_path)}-${local.workflow_region_id}-${local.project_env}",
      url = join("", [
        "https://workflowexecutions.googleapis.com/v1",
        "/projects/${local.project}",
        "/locations/${local.workflow_region}",
        "/workflows/${local.app_name_short}-wkf-${basename(file_stem_path)}-${local.workflow_region_id}-${local.project_env}",
        "/executions"
      ])
    }
  }
}

# Creates the current project workflows to be deployed.
resource "google_workflows_workflow" "workflow" {
  for_each        = local.workflows_list
  name            = "${local.app_name_short}-wkf-${basename(each.key)}-${local.workflow_region_id}-${local.project_env}"
  project         = local.project
  region          = local.workflow_region
  description     = trimsuffix(each.key, ".yaml")
  service_account = data.google_service_account.workflows_sa.id
  source_contents = each.value
}

output "workflows" {
  value = {
    for key, workflow in google_workflows_workflow.workflow :
    key => merge(workflow, local.workflows_map[key])
  }
}
