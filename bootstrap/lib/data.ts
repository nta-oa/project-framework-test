import { BigQuery } from "@google-cloud/bigquery";
import nunjucks from "nunjucks";
import type { ZodSchema } from "zod";
import z from "zod";
import { parse } from "zod-error";
import type { Logger } from "winston";
import path from "node:path";

import type { Config } from "./config";
import { pipe, reduce } from "ramda";

/**
 * @typedef {Object} QueryBqOptions
 * @property {string} queryName - The path of the sql template relative to the /sql folder
 * @property {any} params - Parameters to substitute in the query
 * @property {ZodSchema} schema - The schema to validate the query result against
 */
type QueryBqOptions<T> = {
  queryName: string;
  schema: ZodSchema<T>;
  params?: any;
};

/**
 * @typedef {Object} Dependencies
 * @property {Logger} logger - The Winston logger instance
 * @property {Config} config - The application config
 */
type Dependencies = { logger: Logger; config: Config };

/**
 * Sql query manager for bigquery
 */
export class Data {
  private readonly bigQuery: BigQuery;
  private readonly logger: Logger;
  private readonly config: Config;

  constructor({ logger, config }: Dependencies) {
    this.logger = logger;
    this.config = config;
    this.bigQuery = new BigQuery({
      projectId: this.config.gcp.project,
    });

    nunjucks.configure(path.resolve("sql"), {
      autoescape: true,
    });
  }

  private mapRow = pipe(
    Object.entries,
    reduce((acc, [key, value]) => {
      if (typeof value === "object") {
        if (value !== null) {
          value = parseFloat(value);
        }
      }

      return {
        ...acc,
        [key]: value,
      };
    }, {})
  );

  /**
   * Render the sql template file, executes a query against BigQuery and validate result against zod schema
   *
   * @param {QueryBqOptions} options - The options to execute the query
   */
  async query<T>({
    params,
    schema,
    queryName,
  }: QueryBqOptions<T>): Promise<z.infer<typeof schema>[]> {
    const query = nunjucks.render(queryName, {
      ...params,
      ...this.config.gcp,
    });

    this.logger.debug(`SQL query ${queryName}`);
    this.logger.debug(query);
    this.logger.debug(params);

    const [rows] = await this.bigQuery.query({
      query,
      params,
      useLegacySql: false,
      parameterMode: "NAMED",
      wrapIntegers: false,
      useQueryCache: true,
      jobPrefix: this.config.appName + "-" + this.config.gcp.env,
    });

    // if (queryName === "filters/product.sql") {
    //   console.dir(rows);
    // }

    return parse(z.array(schema), rows.map(this.mapRow), { maxErrors: 1 });
  }
}
