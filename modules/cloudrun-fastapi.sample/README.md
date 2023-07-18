# README - Sample module for FastAPI on Google Cloud Run

## Purpose

This document aims to give information on the current module which is dedicated
to be a base template for building REST APIs using the FastAPI framework.

## Content

Within the folder `api/`, structure and tests are provided to showcase common patterns.
None of it should be kept as-is, or taken too literally. They are merely examples to help you get started.

In contrast, some files must be left unchanged or kept in the same overall format:
- `main.py`
- `application.py`
- and, as much as possible, the existing utils in `helpers/` and `wrappers/`.
  They can however be completed, or extended.


## Module description

### Architecture

This module contains the implementation of the configuration API. It is based
on the use of `FastAPI` library.

`FastAPI` brings flexibility in the implementation of API making them
compatible with Swagger.

The current module template implements the hexagonal architecture a common pattern
for n-tier web applications.

### Components

The main components are:

  | Component name | Comment                           |
  | -------------- | --------------------------------- |
  | controller     | the entrypoint of an API endpoint |
  | services       | the logical of the API endpoint   |


The secondary components are:

  | Component name | Comment                                                                          |
  | -------------- | -------------------------------------------------------------------------------- |
  | validators     | contains controller model validation functions                                   |
  | models         | provides the internal business payload if necessary                              |
  | converters     | provides the functions converting from controller layer to business if necessary |




### How to create a new API endpoint?

The module [controller.py](src/api/default/controller.py) shows how to build a Web API with path operations.

For this to work, you must build a FastAPI application and register the controller, as shown in
[application.py](src/application.py)
