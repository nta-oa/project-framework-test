import { LoggingWinston } from "@google-cloud/logging-winston";
import type { Logger } from "winston";
import winston from "winston";

import type { LogLvl } from "./config";
import { NodeEnv } from "./config";

/**
 * Creates a new Winston logger instance with the specified configuration.
 *
 * @param env {NodeEnv} The current Node environment.
 * @param logLvl {LogLvl} The logging level.
 * @return {Logger} The Winston logger instance.
 */
export function createLogger(env: NodeEnv, logLvl: LogLvl): Logger {
  const transports = [];

  switch (env) {
    case NodeEnv.DEV:
      const consoleTransport = new winston.transports.Console({
        format: winston.format.combine(
          winston.format.timestamp({ format: "YYYY/MM/DD HH:mm:ss" }),
          winston.format.printf(
            (info) => `[${info.timestamp}]: ${info.message}`
          )
        ),
      });
      transports.push(consoleTransport);
      break;
    case NodeEnv.PROD:
      const stackDriverTransport = new LoggingWinston({
        projectId: process.env.GOOGLE_CLOUD_PROJECT,
        serviceContext: {
          service: "default",
        },
      });

      transports.push(stackDriverTransport);
      break;
  }

  return winston.createLogger({
    level: logLvl,
    transports,
  });
}
