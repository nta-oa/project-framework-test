# ======================================================================================== #
#    _____                  __                __   __        _      _    _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __   \ \ / /_ _ _ _(_)__ _| |__| |___ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \   \ V / _` | '_| / _` | '_ \ / -_|_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|   \_/\__,_|_| |_\__,_|_.__/_\___/__/
#
# ======================================================================================== #
variable "app_name" {
  type        = string
  description = "full name of the application"
}

variable "project" {
  type        = string
  description = "google cloud project id"
}

variable "project_env" {
  type        = string
  description = "env (dv, qa, np, pd, cicd)"
}

variable "project_data" {
  type        = string
  description = "google cloud project where datasets are located"
}

variable "env_file" {
  type        = string
  description = "json env file path"
}

variable "revision" {
  type        = string
  default     = "latest"
  description = "version from package.json, used to tag docker container"
}
