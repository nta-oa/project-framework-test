# ======================================================================================== #
#    _____                  __                  ___       _             _
#   |_   _|__ _ _ _ _ __ _ / _|___ _ _ _ __    / _ \ _  _| |_ _ __ _  _| |_ ___
#     | |/ -_) '_| '_/ _` |  _/ _ \ '_| '  \  | (_) | || |  _| '_ \ || |  _(_-<
#     |_|\___|_| |_| \__,_|_| \___/_| |_|_|_|  \___/ \_,_|\__| .__/\_,_|\__/__/
#                                                            |_|
# ======================================================================================== #
# To provide feedbacks after deployment

output "utc_timestamp" {
  description = "Etc/UTC timestamp of last deployment"
  value       = timestamp()
}

output "identity" {
  description = "Email of the cloudrun service account"
  value       = google_service_account.default.email
}

output "service_name" {
  description = "Name of the cloudrun service"
  value       = google_cloud_run_service.default.name
}

output "service_url" {
  description = "url of the cloud run service"
  value       = google_cloud_run_service.default.status[0].url
}

output "deployed_image" {
  description = "revision pushed to artifact registry"
  value       = "gcr.io/${local.project}/${local.app_name}:${local.revision}"
}

output "redis" {
  description = "Host of the redis instance"
  value = {
    host = google_redis_instance.data.host
    port = google_redis_instance.data.port
  }
}
