export SERVICE_NAME=$APP_NAME_SHORT-gcf-$MODULE_NAME_SHORT-ew1-$PROJECT_ENV
export SERVICE_URL=https://$SERVICE_NAME-$CLOUDRUN_URL_SUFFIX.a.run.app

export IDENTITY=$APP_NAME_SHORT-sa-$MODULE_NAME_SHORT-$PROJECT_ENV@$PROJECT.iam.gserviceaccount.com

export TIMEOUT=300