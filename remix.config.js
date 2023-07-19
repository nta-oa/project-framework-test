/** @type {import('@remix-run/dev').AppConfig} */
module.exports = {
  appDirectory: "app",
  ignoredRouteFiles: [
    "**/__tests__/*.spec.ts",
    "**/_components/*",
    "**/_services/*",
    "**/_types/*",
    "**/_i18n/*",
    "**/*.json",
  ],
  cacheDirectory: "./node_modules/.cache/remix",
  assetsBuildDirectory: "./public/build",
  serverBuildPath: "build/app.js",
  publicPath: "/static/build",
  serverDependenciesToBundle: ["ts-extras"],
  future: {},
};
