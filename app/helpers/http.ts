import type { ZodSchema } from "zod";
import type z from "zod";
import { withZod } from "@remix-validated-form/with-zod";
import { validationError } from "remix-validated-form";

/**
 * HTTP methods
 */
export enum HttpMethod {
  GET = "GET",
  POST = "POST",
  PUT = "PUT",
  DELETE = "DELETE",
  PATCH = "PATCH",
  OPTIONS = "OPTIONS",
}

/**
 * HTTP status codes
 */
export enum HttpStatus {
  Accepted = 202,
  MultipleChoices = 300,
  BadRequest = 400,
  MethodNotAllowed = 405,
}

/**
 * Create a successful response
 * @param body
 */
export function successfullAction(body?: BodyInit | null): Response {
  return new Response(body, {
    status: HttpStatus.Accepted,
    statusText: "Successful Operation",
  });
}

/**
 * Create a method not allowed response
 */
export function methodNotAllowed(request: Request): Response {
  const status = HttpStatus.MethodNotAllowed;
  const headers = new Headers({
    "Content-Type": "application/json",
  });
  const error = {
    message: `${request.method} is not allowed for route ${request.url}`,
    status,
  };

  return new Response(JSON.stringify(error), {
    status,
    headers,
  });
}

/**
 * Check if a response is a redirect
 * @param response
 */
export function isRedirect(response: Response): boolean {
  if (
    response.status < HttpStatus.MultipleChoices ||
    response.status >= HttpStatus.BadRequest
  ) {
    return false;
  }

  return response.headers.has("Location");
}

/**
 * Throw a method not allowed error if the request method is not in the list of allowed methods
 * @param request
 * @param methods
 */
export function restrictRouteMethod(
  request: Request,
  methods: HttpMethod[]
): void {
  if (!methods.includes(request.method as HttpMethod)) {
    throw methodNotAllowed(request);
  }
}

/**
 * Parse the request body
 * @param request
 */
async function parseRequestBody(request: Request): Promise<object> {
  switch (request.headers.get("Content-Type")) {
    case "application/json":
      return request.json();
    default:
      return request.formData().then(Object.fromEntries);
  }
}

/**
 * Parse the request params according to its method and Content-Type header
 *
 * GET parse the url query parameters using URL class
 * POST PUT parse the body (json or formdata) according to Content-Type
 * @param request
 * @param schema
 */
export async function parseRequestParams(
  request: Request,
  schema: ZodSchema
): Promise<z.infer<typeof schema>> {
  const validator = withZod(schema);
  let entries;
  switch (request.method) {
    case HttpMethod.POST:
    case HttpMethod.PUT:
      entries = await parseRequestBody(request);
      break;

    case HttpMethod.GET:
    default:
      const url = new URL(request.url);
      entries = Object.fromEntries(url.searchParams);
      break;
  }

  const { data, error } = await validator.validate(entries);

  if (error) {
    throw validationError(error);
  }

  return data;
}
