# ======================================================================================== #
#    ___       _          ___     _               _   _
#   |   \ __ _| |_ __ _  | __|_ _| |_ _ _ __ _ __| |_(_)___ _ _
#   | |) / _` |  _/ _` | | _|\ \ /  _| '_/ _` / _|  _| / _ \ ' \
#   |___/\__,_|\__\__,_| |___/_\_\\__|_| \__,_\__|\__|_\___/_||_|
#
# ======================================================================================== #
locals {
  # import configurations
  dataextraction_folder = "${local.configuration_folder}/dataextraction"
  extraction_configurations = {
    for file_path in fileset(local.dataextraction_folder, "**/*.yaml") :
    file_path => merge(
      yamldecode(
        templatefile(
          "${local.dataextraction_folder}/${file_path}",
          merge(
            local.template_vars,
            {
              datasets = local.dataset_map
              views    = local.view_map
              tables   = local.tables
              mviews   = local.mview_map
              sprocs   = local.sproc_map
              udfs     = local.udf_map
            }
          )
        )
      ),
      {
        id             = "${basename(trimsuffix(file_path, ".yaml"))}-${local.project_env}"
        file_path      = file_path
        file_stem_path = trimsuffix(file_path, ".yaml")
        file_stem      = basename(trimsuffix(file_path, ".yaml"))
      }
    )
  }
}

# -- REST API provider to publish configs to BTDP Data Extraction API
provider "restapi" {
  alias = "dataextraction"
  uri   = local.apis_base_url.dataextraction
  headers = {
    "Authorization" : "Bearer ${local.is_sbx ? "<none>" : data.google_service_account_access_token.cloudbuild_sa[0].access_token}"
  }
  write_returns_object = true
}

# -- provided configurations for data extraction
resource "restapi_object" "dataextraction_configuration" {
  provider = restapi.dataextraction
  for_each = {
    for file_path, config in local.extraction_configurations :
    # add the id to the for_each key to ensure that changing id
    # will delete and re-create the configuration
    "${config.id}" => config
    if local.is_sbx != true # NOTHING deployed on sandbox
  }
  path = "/v1/configurations"
  data = jsonencode(each.value)
}

output "dataextraction" {
  value = {
    configurations = restapi_object.dataextraction_configuration
  }
}
