# ======================================================================================== #
#     ___           __ _        ___     _            __
#    / __|___ _ _  / _(_)__ _  |_ _|_ _| |_ ___ _ _ / _|__ _ __ ___
#   | (__/ _ \ ' \|  _| / _` |  | || ' \  _/ -_) '_|  _/ _` / _/ -_)
#    \___\___/_||_|_| |_\__, | |___|_||_\__\___|_| |_| \__,_\__\___|
#                       |___/
# ======================================================================================== #
# -- Define Rest API objects to publish configs to BTDP config-interface
# Bucket notifications can be found in buckets.tf. They are kept separate
# as they are not really a configuration for the users to create.

# INITIALIZATION

# -- REST API provider for Configuration Interface API endpoints
provider "restapi" {
  alias = "configinterface"
  uri   = local.apis_base_url.configinterface
  headers = {
    "Authorization" = "Bearer ${local.is_sbx ? "<none>" : data.google_service_account_access_token.cloudbuild_sa[0].access_token}"
  }
  write_returns_object = true
}

# -- Initialize the project in configinterface
resource "restapi_object" "configinterface_project" {
  provider = restapi.configinterface
  count    = local.is_sbx ? 0 : 1

  path = "/v1/projects"
  data = jsonencode({
    "project_id" = local.project
  })
  id_attribute = local.project
  object_id    = local.project
  debug        = true
}


# CONFIGURATIONS

locals {
  # import configurations
  configinterface_folder = "${local.configuration_folder}/configinterface"

  flows_config_files        = fileset(local.configinterface_folder, "flows/**/*.yaml")
  statemachine_config_files = fileset(local.configinterface_folder, "state-machine-flows-actions/**/*.yaml")

  all_config_files = fileset(local.configinterface_folder, "**/*.yaml")
  raw_config_files = setsubtract(
    local.all_config_files,
    flatten([
      local.flows_config_files,
      local.statemachine_config_files,
    ]) # Invalid value with `concat`
  )

  configinterface_variables = merge(
    local.template_vars,
    {
      buckets  = local.bucket_map
      datasets = local.dataset_map
      views    = local.view_map
      tables   = local.tables
      mviews   = local.mview_map
      sprocs   = local.sproc_map
    }
  )

  # rendered provided configuration templates
  ## Flows
  flows_configs = {
    for file_path in local.flows_config_files :
    file_path => {
      path         = "/v1/flows"
      id_attribute = "data/id"
      data = {
        id = "${trimsuffix(basename(file_path), ".yaml")}_${local.project_env}" # flow_id
        steps = yamldecode(
          templatefile(
            "${local.configinterface_folder}/${file_path}",
            local.configinterface_variables
          )
        )
      }
    }
  }

  ## State Machine
  statemachine_configs = {
    for file_path in local.statemachine_config_files :
    file_path => {
      path         = "/v1/state_machine/flows_actions"
      id_attribute = "data/flow_action_id"
      data = yamldecode(
        templatefile(
          "${local.configinterface_folder}/${file_path}",
          local.configinterface_variables
        )
      )
    }
  }

  ## Merge all configs
  provided_configs = merge(
    local.flows_configs,
    local.statemachine_configs,
  )

  # rendered raw configuration templates
  raw_configs = {
    for file_path in local.raw_config_files :
    file_path => yamldecode(
      templatefile(
        "${local.configinterface_folder}/${file_path}",
        local.configinterface_variables
      )
    )
  }
}

# provided configs: defined based on examples: flows, state-machine
resource "restapi_object" "configinterface_provided_configs" {
  provider = restapi.configinterface

  for_each = {
    for k, v in local.provided_configs : k => v
    if local.is_sbx != true # NOTHING deployed on sandbox
  }
  path         = each.value.path
  id_attribute = each.value.id_attribute
  data         = jsonencode(each.value.data)
  debug        = true
}

# raw configs: not yet fully integrated, but accessible with custom parameters
resource "restapi_object" "configinterface_raw_configs" {
  provider = restapi.configinterface

  for_each = {
    for k, v in local.raw_configs : k => v
    if local.is_sbx != true # NOTHING deployed on sandbox
  }
  path         = each.value.path
  id_attribute = each.value.id_attribute
  data         = jsonencode(each.value.data)
  debug        = true

  # Assign specific route pattern for each raw configs (if needed)
  # to emulate terraform actions
  create_method = lookup(each.value, "create_method", null) # POST
  create_path   = lookup(each.value, "create_path", null)

  read_method = lookup(each.value, "read_method", null) # GET
  read_path   = lookup(each.value, "read_path", null)

  update_method = lookup(each.value, "update_method", null) # PUT, PATCH
  update_path   = lookup(each.value, "update_path", null)

  destroy_method = lookup(each.value, "destroy_method", null) # DELETE
  destroy_path   = lookup(each.value, "destroy_path", null)
}

# -- outputs
output "configinterface" {
  value = {
    for explicit_path in distinct([
      for _, conf in merge(restapi_object.configinterface_provided_configs, restapi_object.configinterface_raw_configs) :
      "${conf.path}/{${trimprefix(conf.id_attribute, "data/")}}"
    ]) :
    explicit_path => sort([
      for _, conf in merge(restapi_object.configinterface_provided_configs, restapi_object.configinterface_raw_configs) :
      conf.id # null if unknown
      if "${conf.path}/{${trimprefix(conf.id_attribute, "data/")}}" == explicit_path
    ])
  }
}
