import glob from "glob-promise";
import path from "node:path";
import fs from "node:fs/promises";

const destDir = path.join(process.cwd(), "public", "locales");

function computeNewPath(tradPath) {
  const lang = tradPath.split("/").pop().split(".").shift();
  const routePaths = tradPath.split("_i18n").shift().split("/");

  let routeName = routePaths[routePaths.length - 2];

  if (routeName === "routes") {
    routeName = "common";
  }

  return fs.copyFile(tradPath, path.join(destDir, lang, `${routeName}.json`));
}

(async () => {
  const i18nConfigPath = path.resolve("config", "i18n.json");

  const i18nConfig = JSON.parse(await fs.readFile(i18nConfigPath));
  await Promise.all(
    i18nConfig.supportedLngs.map((lng) =>
      fs.mkdir(path.resolve("public", "locales", lng), { recursive: true })
    )
  );

  const base = path.join(process.cwd(), "app");
  const files = await glob(`${base}/routes/**/_i18n/*.json`);

  return Promise.all(files.map(computeNewPath));
})();
