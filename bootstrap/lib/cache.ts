import { createClient } from "redis";
import type { RedisClientOptions } from "redis";
import ms from "ms";
import { millisecondsToSeconds } from "date-fns";
import { pipe } from "ramda";
import type { Logger } from "winston";
import type { ZodSchema } from "zod";
import type z from "zod";

/**
 * @typedef {Object} Dependencies
 * @property {Logger} logger - the winston logger instance
 */
type Dependencies = {
  logger: Logger;
};

/**
 * Wrapper around Redis used to cache user information and data from BigQuery.
 */
export class Cache {
  private readonly redisClient: ReturnType<typeof createClient>;
  private readonly logger: Logger;

  /**
   * @param {Dependencies} dependencies - The dependencies required by the `Cache` class.
   * @param {RedisClientOptions} options - The options for the Redis client.
   */
  constructor({ logger }: Dependencies, options: RedisClientOptions = {}) {
    this.redisClient = createClient(options);
    this.logger = logger;
  }

  /**
   * Converts a duration in string format to seconds.
   *
   * @param {string} ttl - The duration in string format, for example "1d" for 1 day, "1h" for 1 hour, etc.
   * @returns {number} The duration in seconds.
   */
  private formatTtl = pipe(ms, millisecondsToSeconds);

  /**
   * Connect to redis server
   */
  async connect(): Promise<void> {
    await this.redisClient.connect();
    this.logger.debug("Redis connected");
  }

  /**
   * Retrieves all values associated with a key from the cache.
   *
   * @param {string} keyGlob - The key to look up in the cache.
   * @param {ZodSchema} schema - The schema to use to parse the value.
   * @returns A promise that will resolve with an object containing the key-value pairs. The value will be parsed using the provided schema.
   *
   */
  async getAll<T = string>(
    keyGlob: string,
    schema: ZodSchema<T>
  ): Promise<Record<string, z.infer<typeof schema>>> {
    this.logger.debug(`Redis get all entries matching ${keyGlob}`);
    const keys = await this.redisClient.keys(keyGlob);
    const data = await Promise.all(keys.map((key) => this.get(key, schema)));

    return data.reduce((acc, value, index) => {
      return {
        ...acc,
        [keys[index]]: value,
      };
    }, {});
  }

  /**
   * Retrieves the value associated with a key from the cache.
   *
   * @param {string} key - The key to look up in the cache.
   * @param {ZodSchema} schema - The schema to use to parse the value.
   * @returns A promise that will resolve with the value associated with the key. The value will be parsed using the provided schema.
   */
  async get<T = string>(key: string, schema: ZodSchema<T>) {
    this.logger.debug(`Redis get ${key}`);
    const value = await this.redisClient.get(key);

    if (!value) {
      return;
    }

    try {
      return schema.parse(JSON.parse(value));
    } catch (err) {
      return schema.parse(value);
    }
  }

  /**
   * Stores a value in the cache.
   *
   * @param {string} key - The key to use to store the value.
   * @param {string|object} value - The value to store in the cache. If the value is an object, it will be serialized to JSON.
   * @param {string} [ttl="1d"] - The time to live (TTL) for the value in the cache, in string format. By default, the value will expire after 1 day.
   * @param {ZodSchema} schema - The schema to use to parse the value.
   * @returns {Promise<void>} A promise that will resolve with a string indicating whether the value was stored successfully ("OK").
   */
  async set<T = string>(
    key: string,
    value: string | object,
    ttl: string = "1d",
    schema: ZodSchema<T>
  ): Promise<void> {
    try {
      if (typeof value === "object") {
        value = JSON.stringify(schema.parse(value));
      }

      await this.redisClient.set(key, value, {
        EX: this.formatTtl(ttl),
      });

      this.logger.debug(`Redis set for ${ttl} ${key}`);
    } catch (err) {
      this.logger.error("Cache set Error");

      throw err;
    }
  }

  /**
   * Clear a value from the cache.
   *
   * @param {string} key - The key to delete
   * @returns {Promise<void>} A promise that will resolve when the key is deleted.
   */
  async clear(key: string): Promise<void> {
    await this.redisClient.del(key);

    this.logger.debug(`Redis delete ${key}`);
  }
}
