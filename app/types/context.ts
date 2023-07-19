import type { AppData } from "@remix-run/node";
import type { Params } from "react-router-dom";
import type { Logger } from "winston";

import type { Data } from "bootstrap/lib/data";
import type { Cache } from "bootstrap/lib/cache";
import type { User } from "bootstrap/lib/user";
import type { Config } from "./config";

export type Context = {
  config: Config;
  logger: Logger;
  cache: Cache;
  data: Data;
  user: User;
};

type Arguments = {
  request: Request;
  params: Params<string>;
  context: Context;
};

export type RemixFunction = (
  args: Arguments
) => Promise<Response> | Response | Promise<AppData> | AppData;

export type __Session = {
  email: string;
  accessToken: string;
  refreshToken: string;
};
