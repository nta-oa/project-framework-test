#!/usr/bin/env node
/* eslint-disable no-console */

import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import ora from "ora";
import fs from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { promisify } from "node:util";
import { exec } from "node:child_process";
import {
  generateIconsConfig,
  generateAppletouchIcons,
  generateFavicons,
  generateMaskIcons,
  generatePwaIcons,
  generateWebManifest,
} from "./lib/icons.mjs";

function help() {
  console.info("PWA Icons generator");
  console.info(
    "generate icons and manifest for PWA, provide at least a 512x512 logo"
  );
  console.info("npm run icons -- --input=logo.png");
  console.info(
    "npm run icons -- --input=logo.png --favicons --pwa=false --appleTouch=false --mask --manifest --config=false --baseUrl=https://cloud.com/"
  );
}

(async () => {
  const argv = await yargs(hideBin(process.argv))
    .options({
      help: { type: "boolean", default: false },
      input: { type: "string", default: path.resolve("logo.png") },
      favicons: { type: "boolean", default: true },
      pwa: { type: "boolean", default: true },
      appleTouch: { type: "boolean", default: true },
      mask: { type: "boolean", default: true },
      manifest: { type: "boolean", default: true },
      config: { type: "boolean", default: true },
      baseUrl: { type: "string", default: "" },
    })
    .parse();

  if (argv.help) {
    help();

    return;
  }

  if (!argv.input.includes("http") && !existsSync(argv.input)) {
    throw new Error(
      "you must provide either a logo.png at the root of the project or a --input=<logo_path_or_url> argument at least 512x512"
    );
  }

  const spinner = ora("generate icons").start();

  const iconsDir = path.resolve("public", "icons");

  if (!existsSync(iconsDir)) {
    await fs.mkdir(iconsDir);
  }

  const promises = [];

  if (argv.favicons) {
    promises.push(generateFavicons(argv.input));
  }

  if (argv.pwa) {
    promises.push(generatePwaIcons(argv.input));
  }

  if (argv.appleTouch) {
    promises.push(generateAppletouchIcons(argv.input));
  }

  if (argv.mask) {
    promises.push(generateMaskIcons(argv.input));
  }

  const [favicons = [], pwaIcons = [], appleTouchIcons = [], maskIcons = []] =
    await Promise.all(promises);

  spinner.text = "generate manifest and update config";

  const fsPromises = [];

  if (argv.manifest) {
    fsPromises.push(generateWebManifest(pwaIcons));
  }

  if (argv.config) {
    fsPromises.push(
      generateIconsConfig(
        [...favicons, ...appleTouchIcons, ...maskIcons],
        argv.baseUrl
      )
    );
  }

  await Promise.all(fsPromises);

  spinner.text = "format manifest.json";

  await promisify(exec)("npx prettier ./public/app.webmanifest --write");

  spinner.succeed("Icons generated under ./public/app-icons/");

  console.info("./config/icons.json has been modified");
  console.info("./public/manifest.json has been created");
})();
