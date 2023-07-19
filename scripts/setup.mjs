#!/usr/bin/node

import prompts from "prompts";
import nunjucks from "nunjucks";
import ora from "ora";
import fs from "node:fs/promises";
import path from "node:path";
import { promisify } from "node:util";
import { exec } from "node:child_process";
import { renderTemplate } from "./lib/helpers.mjs";

nunjucks.configure(path.resolve("scripts", "templates", "setup"), {
  autoescape: true,
});

function renderEnvironmentFiles({ project, projectData }) {
  const envs = ["dv", "qa", "np", "pd"];

  return envs.map((env) =>
    renderTemplate(
      "environments/env.json",
      {
        env,
        project: `${project}-${env}`,
        projectData: `${projectData}-${env}`,
      },
      path.resolve("environments", `${env}.json`)
    )
  );
}

async function cleanGitIgnore() {
  const gitIgnorePath = path.resolve(".gitignore");
  const content = await fs.readFile(gitIgnorePath, { encoding: "utf8" });
  const finalContent = content.split("\n\n\n").shift();
  return fs.writeFile(gitIgnorePath, finalContent);
}

async function updatePackageJson(name, description) {
  const pkgPath = path.resolve("package.json");
  const content = await fs.readFile(pkgPath).then(JSON.parse);

  return fs.writeFile(
    pkgPath,
    JSON.stringify({ name, description, ...content }, null, 2)
  );
}

(async () => {
  const { name, description, project, projectData, demo, ...github } =
    await prompts([
      {
        type: "text",
        name: "name",
        message: "What's the name of the application ?",
        format: (value) => value.replaceAll(" ", "-"),
      },
      {
        type: "text",
        name: "description",
        message: "Describe the application",
      },
      {
        type: "text",
        name: "project",
        message: "The GCP project name (without the -<ENV>)",
        validate: (value) =>
          value.includes(" ") ? "Spaces are not allowed" : true,
      },
      {
        type: "text",
        name: "projectData",
        message: "The GCP project name containing bigquery dataset",
        validate: (value) =>
          value.includes(" ") ? "Spaces are not allowed" : true,
      },
      {
        type: "text",
        name: "githubOwner",
        message: "The name of the github repository owner",
      },
      {
        type: "text",
        name: "githubRepo",
        message: "The name of the github repo",
      },
      {
        type: "confirm",
        name: "demo",
        message: "Do you want a demo todoApp page ?",
        default: "n",
      },
    ]);

  const spinner = ora(
    "update package.json, create environments json and nodemon.json"
  ).start();

  const envVariables = {
    PROJECT: project + "-dv",
    PROJECT_DATA: projectData,
  };

  await Promise.all([
    renderTemplate(
      "nodemon.json.twig",
      { envVariables },
      path.resolve("nodemon.json")
    ),
    renderTemplate(
      "environments/cicd.json",
      github,
      path.resolve("environments", "cicd.json")
    ),
    renderEnvironmentFiles({ project, projectData }),
    cleanGitIgnore(),
    updatePackageJson(name, description),
  ]);

  if (!demo) {
    spinner.text = "clear demo todo list pages";

    await Promise.all([
      fs.rmdir(path.resolve("app", "components", "form")),
      fs.rmdir(path.resolve("app", "routes", "todo")),
      fs.rm(path.resolve("app", "routes", "todo.tsx")),
    ]);
  }

  spinner.succeed(
    "package.json updated, environments json files and .env created"
  );

  const validateSpinner = ora("Lint and validate").start();

  await Promise.all([
    promisify(exec)("npm run validate:lint -- --fix"),
    promisify(exec)("npm run validate:type"),
  ]);

  validateSpinner.succeed("code linted and validated !");

  validateSpinner.succeed("Application is ready to use locally => npm run dev");
})();
