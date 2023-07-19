# BTDP Web Project Framework

- [Remix Docs](https://remix.run/docs)

## Requirements

- docker, docker-compose, nodejs, gcloud CLI

## Installation

```sh
npm i
npm run setup
```
## ***Hooks commands***


- ***hooks:clean***
```Shell
npm run hooks:clean
```
Removes the .husky hooks folder if it exists.
After this command you need to run an ***npm run hooks:install-all*** to reinstall all hooks.

- ***hooks:install***
```Shell
npm run hooks:install
```
Installs husky hooks.
This command needs to be always followed by a ***npm run hooks:install-btdp***. You can also replace both of these commands with ***npm run hooks:install-all***

- ***hooks:install-btdp***
```Shell
npm run hooks:install-btdp
```
Installs btdp hooks.

:exclamation: Husky needs to be installed before this command. For that you can run ***npm run hooks:install***

- ***hooks:install-all***
```Shell
npm run hooks:install-all
```
Installs husky and btdp hooks.

- ***hooks:add-standard-hooksl***
```Shell
npm run hooks:add-standard-hooks
```
Adds pre-commit and pre-push custom hooks. We recommand you to run this command to comply to standard requirements.

- ***hooks:pre-commit***
```Shell
npm run hooks:pre-commit
```
Custumizes your pre-commit hook and adds an ***npm run lint***.

- ***hooks:pre-push***
```Shell
npm run hooks:pre-push
```
Custumizes your pre-push hook and adds an ***npm run packages:test***.

- ***hooks:add***
```Shell
npm run add "<hook_name>" "<additional_commands>"
```
Allows you to add new hooks or extend existing ones with your own commands.
example:
```Shell
npm run hooks:add "pre-push" "npm run test"
```

## Development

```sh
npm run dev
```

This starts your app in development mode, rebuilding assets on file changes, and run redis in docker.

## Build

```sh
npm run build
```

- `build/`
- `public/build/`

```sh
ENV=dv make build

```

This build the app and the docker image

## Deploy

```sh
ENV=dv make deploy

```

This deploy the docker image
