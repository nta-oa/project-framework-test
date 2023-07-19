import z, { ZodError } from "zod";

import i18n from "config/i18n.json";
import server from "config/server.json";
import pkg from "pkg.json";

/**
 * Enum for the different logging levels.
 * @readonly
 * @enum {string}
 */
export enum LogLvl {
  ERROR = "error",
  WARN = "warn",
  INFO = "info",
  DEBUG = "debug",
}

/**
 * Enum for the different node environments.
 * @readonly
 * @enum {string}
 */
export enum NodeEnv {
  DEV = "development",
  PROD = "production",
  TEST = "test",
}

/**
 * Enum for the different project environments.
 * @readonly
 * @enum {string}
 */
export enum ProjectEnv {
  DV = "dv",
  QA = "qa",
  NP = "np",
  PD = "pd",
}

/**
 * Schema for environment variables.
 */
export const EnvVariablesSchema = z.object({
  NODE_ENV: z.nativeEnum(NodeEnv),
  PROJECT: z.string(),
  PROJECT_ENV: z.nativeEnum(ProjectEnv),
  PROJECT_DATA: z.string(),
  REDIS_HOST: z.string(),
  REDIS_PORT: z.string(),
  LOG_LVL: z.nativeEnum(LogLvl).optional().default(LogLvl.DEBUG),
  PORT: z.string().transform((val) => parseInt(val, 10)),
  MOCKED_USER: z.string().optional(),
});

/**
 * Retrieves the application configuration based on the environment variables.
 * @throws {Error} if environment variables are invalid
 * @returns the application configuration
 */
export function getConfig() {
  try {
    const result = EnvVariablesSchema.parse(process.env);

    return {
      appName: pkg.name,
      nodeEnv: result.NODE_ENV,
      port: result.PORT,
      gcp: {
        project: result.PROJECT,
        projectData: result.PROJECT_DATA,
        env: result.PROJECT_ENV,
      },
      logLvl: result.LOG_LVL,
      redisUrl: `redis://${result.REDIS_HOST}:${result.REDIS_PORT}`,
      mockedUser: result.MOCKED_USER,
      i18n,
      server,
    };
  } catch (err) {
    if (err instanceof ZodError) {
      err.issues.forEach(({ path, message }) => {
        process.stdout.write(`${path} => ${message}\n`);
      });
    }

    throw new Error();
  }
}

/**
 * The application configuration.
 * @typedef {Object} Config
 * @property {NodeEnv} nodeEnv - the node environment
 * @property {string} port - the port
 * @property {Object} gcp - the Google Cloud Platform configuration
 * @property {string} gcp.project - the project ID
 * @property {string} gcp.projectData - the project ID of bigquery
 * @property {ProjectEnv} gcp.env - the project environment
 * @property {LogLvl} logLvl - the logging level
 * @property {string} redisAddress - the Redis address
 * @property {Object} i18n - the i18n configuration
 * @property {Object} server - the server configuration
 */
export type Config = ReturnType<typeof getConfig>;
