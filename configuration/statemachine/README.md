# README — `configuration/statemachine`

## Purpose

This directory contains template files for **YAML** configurations to manage triggers within the BTDP State Machine V2
API.

Triggers allow to trigger a Cloud Workflow or an HTTP endpoint when one or multiple SDDS Global Business Objects(s) have
been updated during a specified timeframe.
See the [Confluence documentation](https://confluence.e-loreal.com/display/BTDP/3.17+State-machine#id-3.17Statemachine-Usage)
for more details.

## Directory structure

```
|── triggers/                        Contains templates to define triggers.
```

Files ending with `.yaml.sample` are provided to showcase common parameters.

## Functioning concept

Configuration template files are given as input to the Terraform provider `Mastercard restapi`, which allows to manage
objects in a RESTful API, in this case here the BTDP State Machine V2 API through Apigee. The Terraform provider is
essentially a terraform-wrapped `cURL` client.

Any common references (project_env, ...) in the template files will be replaced by its value while it is being parsed.
An additional file `../variables.json` allows to create user-defined references to limit repetitions.

Please refer to both documentation from:

- the BTDP module `25-state-machine-v2` module,
- and, the terraform provider [restapi](https://registry.terraform.io/providers/Mastercard/restapi/latest/docs)
  (allowing to emulate a resource with a REST API).

## Requirements

### When deployed in CI/CD triggers

To consume the API, the caller must be part of the AD group `IT-GLOBAL-GCP-BTDP_DATASRV_STATEMACHINE@loreal.com`.

When creating a trigger, an ACL is positioned using the `group` attribute in the payload.
The caller must also be part of this group to update or delete the aforementioned trigger.
