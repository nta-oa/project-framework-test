import { createRequestHandler } from "@remix-run/express";
import express from "express";
import path from "node:path";

import { getConfig, NodeEnv } from "./lib/config";
import { createLogger } from "./lib/logger";
import { Cache } from "./lib/cache";
import { Data } from "./lib/data";
import { getUser } from "./lib/user";

const BUILD_DIR = path.resolve("build");
const REMIX_FILE = path.join(BUILD_DIR, "app");

/**
 * Main application bootstrap self invoking function.
 * Starts the server, sets up middleware, initializes application context
 * and handle requests with the Remix framework.
 */
(async () => {
  try {
    /**
     * Initialize context
     */
    const config = getConfig();
    const logger = createLogger(config.nodeEnv, config.logLvl);
    const cache = new Cache({ logger }, { url: config.redisUrl });
    const data = new Data({ config, logger });

    await cache.connect();
    const app = express();

    /**
     * Remove http header added by express
     */
    app.disable("x-powered-by");

    /**
     * Serve static files in public folder under /static
     */
    app.use("/static", express.static("public"));
    app.use("/sw.js", express.static("public/sw.js"));

    /**
     * Handle all requests with the Remix framework and pass global services in Remix context.
     *
     * @param {express.Request} req - Express request object.
     * @param {express.Response} res - Express response object.
     * @param {express.NextFunction} next - Express next middleware function.
     * @returns {RequestHandler}
     */
    app.all("*", async (req, res, next) => {
      if (config.nodeEnv === NodeEnv.DEV) {
        purgeRequireCache();
      }

      const user = await getUser({ config, data, logger, cache }, req);

      return createRequestHandler({
        build: require(REMIX_FILE),
        mode: config.nodeEnv,
        getLoadContext: () => ({ config, logger, data, cache, user }),
      })(req, res, next);
    });

    app.listen(config.port, () => {
      logger.debug(`Server listening on port: ${config.port}`);
    });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error("Something fails while bootstraping the app");
    // eslint-disable-next-line no-console
    console.error(err);
  }
})();

/**
 * Helper function to purge the require cache for all modules in the build directory.
 * This is used for "server side HMR" in development mode.
 */
function purgeRequireCache() {
  for (const key in require.cache) {
    if (key.startsWith(BUILD_DIR)) {
      delete require.cache[key];
    }
  }
}
