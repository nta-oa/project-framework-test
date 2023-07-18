# CHANGELOG - Project framework

This file contains all the changes in the module grouped by each version.

Please add upcoming changes to the `CHANGELOG.pending.md` file to avoid unexpected results after rebase.
A single version should be prepared at a time to avoid conflicts here.

Dates are in YYYY/MM/DD format.


# v2.8.2 - 2023/07/07

## Data Transmission

- Fixed the service account name for data transmission that was the wrong one in v2.8.1.


---

# v2.8.1 - 2023/07/06

## Data Transmission

- Fixed an issue where the data transmission was not working properly because of missing permissions.

## Update

- Fixed wrong file names in the version manifest.


---
# v2.8.0 - 2023/07/04

## Makefiles

- Enforce a minimal version for GNU Make; since the system version on MacOS has become too old.
  It needs to support the `:=` operator in define block statements
- Fix option in a `find` command that was not working in a cloudbuild context

### Init

- Fixed a terraform resource import that prevented the deployment of the framework on brand new projects.

## Setup

### CICD

- Put back the permissions to allow one environment's CICD to call the next one's.
  This was removed in a previous version, but it is needed for the CICD to work.

## Configurations

### State Machine

- Added the State Machine v2 configuration
- Deprecated the State Machine v1 (configuration/configinterface/state-machine-flows-actions/)

### Access Management

- Migrate the API used for rules from `v1` to `v2`. This should be an invisible change for users.


---
# v2.7.1 - 2023/06/14

## All IaC
- Lock the version of the google provider to 4.65.2 to avoid a bug included by the 4.66


---
# v2.7.0 - 2023/06/07

## All IaC
- Change terraform requirement from `~> 1.3.7` to `~> 1.3` to support higher versions locally


## All Makefiles
- fix an issue regarding Make variables declared with `define` that was causing huge re-evaluation loops.
  By using the `:=` operator to evaluate immediately and only once
- use the `:=` operator for other vars as well
- group remaining .PHONY targets to declare them all at once above the help
- remove remaining references to `IS_SANDBOX`. Since sandbox are not longer supported
- add `2>/dev/null` to relevant `find` commands to hide errors when no file was found

## Root Makefile
- Rely on `includes/targets/terraform.mk` for the IaC targets instead
- Remove target `pause-schedulers` for sandboxes as there is no sandbox anymore

## Module.mk
- Move the Python targets to `includes/targets/python.mk`
- Move the targets for each module type to `includes/module_types/{module_type}.mk`
- Rely on `includes/targets/terraform.mk` for the IaC targets instead
- Remove target `pause-schedulers` for sandboxes as there is no sandbox anymore
- Fetch the value of `CLOUDRUN_URL_SUFFIX` only once

### Init Makefile
- Rely on `includes/targets/terraform.mk` for the IaC targets instead
- Include common-variables instead of redefining the same vars. Only the cicd has its own as it deploys on all envs at once

### CI/CD Makefile
- Rely on `includes/targets/terraform.mk` for the IaC targets instead

## Includes
- Regroup and standardize the IaC targets from all Makefiles in `includes/targets/terraform.mk`
- Move the Python targets from module.mk to `includes/targets/python.mk`
- Move the targets for each module type from module.mk to `includes/module_types/{module_type}.mk`.
  A file `help.txt` is provided alongside for documentation.
  Each module type should defined all the targets mentionned in help; but can be empty if not needed

- Regroup `failfast-checks` and `pre-requisite` into the file `pre-requisites`.
  It can and must be imported first now in each Makefile.
  Remove java from REQUIRED_EXECUTABLES since not used

- In common-variables, remove `BRANCH` var since it is unused


## Setup
The setup process was simplified:
- There is now an `init-all` rule available in the root Makefile to run the `init` setup on all environments at the same time.
- The service accounts permissions are now given in the `init` part instead of `cicd`, allowing the use of the framework on a development environment without setting up the CICD.
- The mandatory external accesses are now given in the `init` instead of `access` setup.
- The developer group is now requested in the `instantiate-template.sh` script, it is used to give all the permissions needed to deploy on `dv` environment to the developers.


## Modules
- Update to `0.12` the version of the shared `loreal` package in sample cloudrun module for FastAPI
- **Call `setup_logging()` independently of BTDPFastAPI instantiation.**
- **Change the `apigee_access_secret_id` parameter to `apigee_permission_checker`** for token access control using a
  secret or a GCS object resource.
- Run a single Uvicorn process instead of running Gunicorn with multiple Uvicorn workers in container for FastAPI


### Datasets

- Allow the reference to already existing datasets. This will make it possible to create resources in those datasets from the framework without the dataset being created in the framework. See the documentation for datasets or the `configuration/datasets/external_dataset.yaml.sample` for how to use it.

### All other BQ resources

- **The attribute `dataset_id` has been deprecated and is not replaced by `dataset` to make it clearer that it's not directly the id of the dataset to use.**


## Environment
- Remove `sbx.json.template` file since sandbox are not longer supported


---
# v2.6 - 2023/05/05

## Modules
- Update to `0.9` the version of the shared `loreal` package in sample modules
- **Fix runtime of sample modules for Cloud function by upgrading it to `python310`. And raise timeout to 5 minutes.**
- Add module cloudrun-fastapi.sample demonstrating FastAPI framework to build Web APIs.
- The `make local-test` target in module.mk is now working for both FastAPI and Flask-RestX. It uses the default command of Dockerfile

## Makefiles
- **`GUNICORN_DEBUG` has been renamed to `LOCAL_TEST`**. When provided, it indicates that the app runs locally.
  In particular, logging should then be set up for a local runtime; instead of for Google Compute services
- Provide test env variables to GCF when running `local-test` and run the function in debug mode to show some logs.
- **Fix build of requirements in dist folder of Google function**
- Integrate Python end-to-end (e2e) tests at module-level. As implemented in btdp-am repository.
  Global e2e tests can be made using a dedicated module.
- Build a static test env file `.env` when preparing tests for a module.
  It is provided for convenience, since its plain values make it usable as an env file for both docker, or a debugger locally.
- Add new module_type `gcb` to support modules without Dockerfile. For instance, to create modules dedicated for e2e-tests.

- **Fix check of explicit versioning of packages mentioned in requirements.txt**
- Fix pylint check that were looking at non-Python files too. Now only Python files should be considered

- Regroup the `%-all` and `%-module-<MODULE_NAME>` commands in a generic way. Any matching target will be run
- Rework some existence checks for needed files and directories.
  In particular, fail fast if BUILD_REQUIREMENTS is missing; or for unsupported module TYPE

## Configurations
- New samples have been created to handle the file integration pipeline defined in Confluence: https://confluence.e-loreal.com/display/BTDP/4.4.6.1+File+integration+pipeline.

## IaC
- Fix the issue #144 regarding the bad order of clustering fields in Bigquery tables
- Fix the permission given to the AMaaS service account to access the project. Moved the permission to setup/access.
- Added a `schema_string` to the table attributes. It is used in the workflows/sprocs when loading files with the ingestion pipeline.
- Fix the issue #151 regarding clustering and partitioning in materialized views

## Workflows
- A subworkflows has been created to call sprocs more easily (**WAITING FOR DOCUMENTATION IN CONFLUENCE**)

## CI/CD
- Enable uniform bucket-level access on deploy bucket
- **Remove refs of integration bucket.** It was used in btdp repository for e2e-tests with Google Workflows, but is now unused.
  It might be re-added differently if global e2e-tests become supported in framework.
- Add step in module deploy triggers to run e2e-tests (if any); after deploy and before goto next.
  By default, only on `qa`. A new boolean parameter `e2etests` is available in triggers env configuration.

## Init
- Enable uniform bucket-level access on deploy bucket
- **repair the target `all` of the Makefile of setup/init. The target `iac-clean-state` needs `iac-prepare` to have already been run**
- in target `iac-clean-state`, only try to import Apigee app in Terraform state if it is missing from it

## Modules
- Update to `0.9` the version of the shared `loreal` package in sample modules
- **Fix runtime of sample modules for Cloud function by upgrading it to `python310`. And raise timeout to 5 minutes.**

## Miscellaneous
- Fix some trailing whitespaces blocking commits
- Add lenient Mypy configuration file `.mypy.ini` to enforce using type hints in Python modules.
  No check is performed yet on type hints consistency


---
# v2.5.1 - 2023/02/15

## Setup

### Access
- **Breaking change** Renamed the access file to `core_btdp_access.yaml`.
- `variables.json` is now optional

## Bugfix
- `setup/access` was missing from the manifest, preventing the proper update of the framework.


---
# v2.5.0 - 2023/02/15

**This version contains breaking changes**

## README:
- Move the content related to usage from the READMEs of sample modules to a common README to explain how to interact with modules

## Bin:
- Removed the script `deploy-apigee` and its dependencies. Since unneeded anymore

## CICD:
- Set `py3.10-tf1.2.7-slim` version for _generic-build_ by default.

## Makefiles:
- Updated the target `deploy-apigee` of module.mk to rely on the Apigee Deployer API
- Fixed a crash in the deploy-apigee rule of module.mk caused by hyphens in the appname
- Built a pre-signed index url for the shared Python package `loreal`; as documented in Confluence.
  Its lifespan should be enough for the whole build duration (<1h)
- Installed the lib in module samples when referenced in _requirements.txt_.
  For GCR, the given arg still has to be used in _Dockerfile_ as shown in sample
- **New executables as pre-requisite: `tar`, `zip`, `unzip`. They should be there per default, but, if not, can be installed as-is with brew or apt**
- **python 3.10 is now required, instead of python 3.8**
- Set `py3.10-tf1.2.7-slim` version for _generic-build_ by default for gcb builds.

## Modules:
- **Any module ending with `.sample` will now be ignored for the CICD and makefile commands.**
- Used the Python package `loreal` in module samples to replace copy-pasted commons. Copy-pasting can still be used as a temporary remediation
- **Removed unneeded installs in _Dockerfile_. They were needed for the PostgreSQL package (psycopg); which is rarely used**
- Removed auto-remediation behaviors in _constants.py_ when some vars are missing like: APP_NAME_SHORT, PROJECT_ENV, MODULE_NAME_SHORT.
  They must be provided explicitly as usual
- Set `1.2.7` as terraform version in iac providers.


## External permissions:
- Added *workflows.invoker* to the data integration permissions so it can call workflows.

## Configurations:

### Stored Procedures:
- Fixed a bug that prevented from deploying stored procedures referencing datasets or tables that were not yet deployed.

### Access management:
- Added a configuration for DLS subscriptions using a new `restapi_object`, and authorize their groups on the list of datasets provided in each configuration

### External tables:
- An optional block has been added to table configurations, to back them with data outside BigQuery (like from a Google Sheet)

### Authorized Views:
- Added a configuration for authorized views on datasets


---
# v2.4.0 - 2022/11/02

**This version contains breaking changes**

The framework now has an update system. Any file and folder managed by the updater **shall not** be modified in any way. You can find the list of those files and folders in the `.version_manifest` file.

**You need to run the `./iac/migrate_iac` once and ONLY ONCE to update the terraform state without risking losing data.**

## General changes:
- Modified the external_access.yaml to allow configinterface to access the project.
- Added the `.github/CODEOWNERS` to the framework to force reviews of the framework to the Data Services team. Be careful to remove/change it if you don't completely replace the `.github` folder when creating a new use case so you aren't forced to have us as reviewers.

## Init:
- Secret Manager API is now activated during the init process.
- Cloud Scheduler API is now activated during the init process.

## CI/CD:
- force to provide an explicit tag in cicd env_file for _generic-build_ image version.
- use `1.3.7-slim` version for _generic-build_ by default.


## Makefiles:
- use `1.3.7-slim` version for _generic-build_ by default for gcb builds.
- The rule `update` has been added to call the updater.
- `make iac-clean` will now only clean if you changed environments to gain time, on **every Makefile**.
To force clean, remove the `iac/.iac-env` file and run the iac-clean rule of the desired makefile.
## Configurations:
- The terraform configuration is now module based to support the updater changes:
  - the `core` module is for the internal working of the framework and shall not be modified.
  - the `custom` is where you can add your own custom terraform configurations.
- **BREAKING CHANGE**: You have to run `./iac/migrate_iac` **ONLY ONCE** to migrate all your resources to the new terraform modules.
- The cloudrun_url_suffix variable is now available to inject into your configurations. It contains the suffix specific to your projects in the name of your cloudruns.
- There's now an example of how to set your target environments for SDDS depending on your project environment. (see configuration/workflows/multi_env_variable.yaml.sample)

### Schedulers:
- You can now access your workflows url in your schedulers
- **BREAKING CHANGE**: The schedulers are now named automatically based on the file name. For example, for a scheduler that was named `appname-sch-sample_scheduler-eu-dv`, you would only need to set the file name to `sample_scheduler.yaml` in the configuration.

### Bucket configurations:
- You can now define the project of the topic you want to subscribe to.
- To create a notification to btdp-topic-arrival-pd (for dataintegration and flows), you
now need to add `use_flows: true` instead of the `notification` attributes to your
bucket configuration. You can still use `notification` for your own pub/sub topics.

### BQ Jobs:
- You can now use the variables from Terraform in your BQ Jobs

### Datasets:
- **BREAKING CHANGE**: The permissions system for the datasets has been changed to prevent them from being overwritten. It now uses google_bigquery_dataset_access instead of google_bigquery_dataset_iam_binding. You can find the migration procedure at line 122 of the [iac/bq_datasets.tf](iac/bq_datasets.tf) file.

### Flows:
- **BREAKING CHANGE**: The flow_id will have the environment automatically appended to it to prevent conflicts. You will have to change your state machine configurations and anything that depends on your flows.

## Modules:
- require `1.3.7` as terraform version in iac providers.
- Black will give you the diff instead of only telling you that your code is bad.
- A new Makefile rule has been added: `make local-test-module-<module>`. It calls the local-test rule of the module.mk but can be used from the root of the repository, like the other `module` rules.
- The deploy-apigee script has been fixed and now uses the proper secret to deploy an API.

### GCR:
- update module `template` and add some structure and test examples to showcase common patterns.
- prepend additional common variables to `test_env.sh`:
  APP_NAME, APP_NAME_SHORT, MODULE_NAME, MODULE_NAME_SHORT, PROJECT_NUMBER, CLOUDRUN_URL_SUFFIX
- a UID is now generated for each request and both:
  - add it as prefix in every log message
  - add it in response headers as `X-REQUEST-UID` to allow retrieving log entries
- The module couldn't be deployed because of some pylint issues that have been fixed.

### GCF
- A new module template for Cloud Functions v2 has been made. It can be found in `modules/template-gcfv2`. It should be used instead of Cloud Functions v1 whenever possible.
- Cloud Functions deployment now works properly on Mac when using the framework without having to do some alias tricks for `md5`.
- A sample scheduler was added to the GCFv2 template to have an example of call.


---
# 2022/05/23

## Misc:
- Improved the `./environments/instantiate-template.sh` script to include the GitHub org, repository and create the `.app_name` file.
- Added a `sbx.json.template` file for sandbox deployment.
- The `<project>-sa-workflows-<env>` service account is now created in `setup/init` instead of only when there are workflows to deploy in the configurations.

## Makefile:
- `make iac-clean` will now only clean if you changed environments to gain time.

## Configurations

### Misc

- New samples have been created.

### Datasets

- **BREAKING CHANGE**: The `dataset_id` is now generated from the file's name.
- **BREAKING CHANGE**: The `domain_code` has been removed and will not be part of the dataset_id anymore. The dataset id is now `<app_name>_ds_<confidentiality>_<dataset_file_name>_<location>_<env>`.
- The location is now optional with the project's location as the default value.
- **DEPRECATION**: The `criticity` deprecated attribute has been removed. You shall now use `criticality`.
- `delete_contents_on_destroy` is now `false` by default for safety.
- Added `deletion_protection` optional attribute. It is `true` by default and prevents the accidental deletion of the dataset. You will have to deploy your resources with the value at `false`, remove the file then redeploy to delete a dataset that had the value at `true`.

### Tables

- **BREAKING CHANGE**: The `version` will automatically be added to the `table_id`, there is no need to add it manually anymore.
- **BREAKING CHANGE**: The `dataset_id` should be the name of the dataset file in the configuration.
- Partitioning and clustering are now completely optional parameters.
- The `previous_version` is no longer used.

### Views

- **BREAKING CHANGE**: The `version` will automatically be added to the `view_id`, there is no need to add it manually anymore.
- **BREAKING CHANGE**: The `dataset_id` should be the name of the dataset file in the configuration. It is still required to put the full path in the SQL query.
- Added `deletion_protection` optional attribute. It is `true` by default and prevents the accidental deletion of the dataset. You will have to deploy your resources with the value at `false`, remove the file then redeploy to delete a dataset that had the value at `true`.

### Materialized Views

- **BREAKING CHANGE**: The `version` will automatically be added to the `view_id`, there is no need to add it manually anymore.
- **BREAKING CHANGE**: The `dataset_id` should be the name of the dataset file in the configuration. It is still required to put the full path in the SQL query.
- Added `deletion_protection` optional attribute. It is `true` by default and prevents the accidental deletion of the dataset. You will have to deploy your resources with the value at `false`, remove the file then redeploy to delete a dataset that had the value at `true`.

### User defined functions

- **BREAKING CHANGE**: The `dataset_id` should be the name of the dataset file in the configuration.
- You can now reference a dataset, table, view, and materialized view as parameters in the configuration of the UDF.

### Stored procedures

- **BREAKING CHANGE**: The `dataset_id` should be the name of the dataset file in the configuration.
- **BREAKING CHANGE**: You can now define the body of the Stored Procedure in an SQL file of the same name, you should not define `definition_body` in the procedure's configuration in that case.
- You can now reference a dataset, table, view, and materialized view as parameters in the configuration and SQL file of the procedure.

### Workflows

- The monitoring will be done automatically in the library subworkflows. You still need to add it to your subworkflows.
- You can now reference a dataset, table, view, materialized view, and stored procedures as parameters in the configuration and SQL file of the workflows.
- The `flow_id` of the workflows is now generated automatically with the format `UC_<workflow_file_name>_<env>`.


---
# 2022/04/06

## Workflows:

### Monitoring subworkflows:

**BREAKING CHANGE:** The `start_monitoring` and `end_monitoring` now don't take the `project` parameter as it should always have referred to the `itg-btdpback-gbl-ww-<env>` project.

## Bigquery Views:

**BREAKING CHANGE:** The string `project` was previously used to variabilize the project id linked to the dataset of the view. It could cause problems if you wrote `project` anywhere else in the query. You will now need to use `${project}` instead.
- Removed the `gdpr`, `privacy`, `confidentiality`, `data_domain`, `data_family`, and `data_gbo` parameters that were not used.

## Bigquery Datasets:

- Deprecated `criticity` as a parameter. It is now `confidentiality`; both will work until a further update.
- Removed the `data_domain` and `owned_by` parameters that were not used.

## Bigquery Tables:

- The `previous_version` parameter is not required anymore if the table is v1. It will default to `0`.
- Removed the `gdpr`, `privacy`, `confidentiality`, `data_domain`, `data_family`, and `data_gbo` parameters that were not used.
