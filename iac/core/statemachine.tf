# ======================================================================================== #
#    ___ _        _       __  __         _    _
#   / __| |_ __ _| |_ ___|  \/  |__ _ __| |_ (_)_ _  ___
#   \__ \  _/ _` |  _/ -_) |\/| / _` / _| ' \| | ' \/ -_)
#   |___/\__\__,_|\__\___|_|  |_\__,_\__|_||_|_|_||_\___|
#
# ======================================================================================== #
locals {
  # import configurations
  statemachine_folder = "${local.configuration_folder}/statemachine"

  trigger_configurations = {
    for filepath in fileset(local.statemachine_folder, "**/*.yaml") :
    filepath => yamldecode(
      templatefile(
        "${local.statemachine_folder}/${filepath}",
        merge(
          local.template_vars,
          # Allow referencing other resources based on configurations
          {
            workflows = local.workflows_map
          }
        )
      )
    )
  }

  statemachine_triggers_map = {
    for filepath, config in local.trigger_configurations :
    filepath => {
      id = "${basename(trimsuffix(filepath, ".yaml"))}_${local.project_env}"
      group = config.group
      timeframe = config.timeframe
      gbos = config.gbos
      on_success = config.on_success.type == "workflow" ? {
        type = "workflow"
        project = local.project
        region = local.workflow_region
        name = local.workflows_map[config.on_success.workflow].name
        argument = config.on_success.argument
      } : config.on_success.type == "http" ? config.on_success : null
    }
  }
}

# -- REST API provider for State Machine V2 API endpoints
provider "restapi" {
  alias = "statemachine"
  uri   = local.apis_base_url.statemachine
  headers = {
    Authorization = "Bearer ${data.google_service_account_access_token.cloudbuild_sa[0].access_token}"
  }
  write_returns_object = true
}

# -- provided configurations for triggers
resource "restapi_object" "statemachine_triggers" {
  provider = restapi.statemachine

  for_each = {
    for k, v in local.statemachine_triggers_map : k => v
    if local.is_sbx != true # NOTHING deployed on sandbox
  }

  path         = "/v2/triggers"
  data         = jsonencode(each.value)
  id_attribute = "data/id"
  debug        = true
}

# -- outputs
# Fetch the updated configs manually since restapi_object requires a refresh for `api_response` to be up-to-date
# Cf. https://github.com/Mastercard/terraform-provider-restapi/issues/81
data "http" "statemachine_triggers_info" {
  for_each = restapi_object.statemachine_triggers

  url = "${local.apis_base_url.statemachine}/v2/triggers/${each.value.id}"
  request_headers = {
    Authorization = "Bearer ${data.google_service_account_access_token.cloudbuild_sa[0].access_token}"
  }
}

output "statemachine" {
  value = {
    triggers = {
      for k, obj in data.http.statemachine_triggers_info : k => jsondecode(obj.response_body)["data"]
    }
  }
}
