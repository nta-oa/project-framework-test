import type { Request } from "express";
import {
  identity,
  includes,
  map,
  pipe,
  pluck,
  sortBy,
  uncurryN,
  uniq,
} from "ramda";
import type { Logger } from "winston";
import z from "zod";

import type { Cache } from "./cache";
import type { Config } from "./config";
import { NodeEnv } from "./config";
import type { Data } from "./data";

type Dependencies = {
  config: Config;
  data: Data;
  cache: Cache;
  logger: Logger;
};

/**
 * Schema used to validate data from bigquery
 */
const userDataSchema = z.object({
  email: z.string().email(),
  countries: z.string(),
  divisions: z.string(),
  zones: z.string(),
});

/**
 * User Access Object from big query
 *
 * @typedef {Object} UserData
 * @property {string} email - The user's email address (must be a valid email address)
 * @property {string} countries - A country code
 * @property {string} divisions - A division code
 * @property {string} zones - A zone code
 */
export type UserData = z.infer<typeof userDataSchema>;

const accessListSchema = z.array(z.string()).optional();

/**
 * Schema used to validate application user access object
 */
export const userSchema = z.object({
  email: z.string().email(),
  countries: accessListSchema,
  divisions: accessListSchema,
  regions: accessListSchema,
});

/**
 * Represent the access right of the current user
 *
 * @typedef {Object} User
 * @property {string} email - The user's email address (must be a valid email address)
 * @property {string[]} countries - An array of strings representing country names
 * @property {string[]} divisions - An array of strings representing division names
 * @property {string[]} zones - An array of strings representing zone names
 */
export type User = z.infer<typeof userSchema>;

/**
 * Get the email of the authenticated user
 *
 * @param {Config} config - The application configuration object
 * @param {Request} req - The incoming request object
 * @returns {string} The email of the authenticated user
 * @throws {"missing user email"} Throws an error if the user's email cannot be determined
 */
function getUserEmail(config: Config /* , req: Request */): string {
  let email: string | undefined;

  switch (config.nodeEnv) {
    case NodeEnv.DEV:
    case NodeEnv.TEST:
    case NodeEnv.PROD:
      email = config.mockedUser;
      break;

    // case NodeEnv.PROD:
    //   email = req.header("X-Goog-Authenticated-User-Email");
    //   break;
  }

  if (!email) {
    throw "missing user email";
  }

  return email;
}

/**
 * A function that takes a key and an array of objects and plucks that key from the array
 * and returns the unique values in that array.
 *
 * @param  key - The key to pluck from the array of objects.
 * @params list - An array of object containing a key matching the first param
 * @returns - An array of unique values alphabetically sorted for the specified key.
 *
 * @example
 * const input = [
 *   { "name": "alfred", role: "admin" },
 *   { "name": "alfred", role: "user" },
 *   { "name": "sarah", role: "admin" }
 * ]
 *
 * getUniqueAccessList("name", input) // ["alfred", "sarah"]
 */
const getUniqueAccessList = pipe(
  uncurryN<string[]>(1, pluck),
  uniq<string>,
  sortBy(identity)
);

const getDivisions = pipe(
  getUniqueAccessList,
  map((division) => division.split("_")[0])
);

/**
 * Checks if the given array of string contains ALL
 *
 * @param list - a list of string
 * @return A boolean which indicate if the user can access all of the given resource eg: country
 */
const hasAllAccess = includes("ALL");

/**
 * Formats user data into a user object.
 *
 * @param {string} email The loreal email of the user
 * @param {UserData[]} data The array of user data to format.
 */
function formatUserData(email: string, data: UserData[]) {
  const countries = getUniqueAccessList("countries", data);
  const divisions = getDivisions("divisions", data);
  const regions = getUniqueAccessList("zones", data);

  const user: User = {
    email: email,
  };

  if (!hasAllAccess(countries)) {
    user.countries = countries;
  }

  if (!hasAllAccess(divisions)) {
    user.divisions = divisions;
  }

  if (!hasAllAccess(regions)) {
    user.regions = regions;
  }

  return user;
}

/**
 * Get the user's Object
 *
 * @param {Dependencies} dependencies - An object containing dependencies needed for this function
 * @param {Request} req - The incoming request object
 * @return the user object or undefined
 */
export async function getUser(
  { cache, config, data, logger }: Dependencies,
  req: Request
) {
  try {
    const email = getUserEmail(config);
    const cachedUser = await cache.get<User>(email, userSchema);

    if (cachedUser) {
      return cachedUser;
    } else {
      const userData = await data.query<UserData>({
        queryName: "auth/user-rights.sql",
        params: { email },
        schema: userDataSchema,
      });

      const user = formatUserData(email, userData);

      await cache.set(
        email,
        user,
        config.server.auth.cacheDuration,
        userSchema
      );

      return user;
    }
  } catch (err) {
    logger.debug("user error", err);
  }
}
