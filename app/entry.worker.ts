/// <reference lib="WebWorker" />

import { json } from "@remix-run/server-runtime";

export type {};
declare let self: ServiceWorkerGlobalScope;

const STATIC_ASSETS = ["static/", "sw.js"];

const ASSET_CACHE = "asset-cache";
const DATA_CACHE = "data-cache";
const DOCUMENT_CACHE = "document-cache";

function debug(...messages: any[]) {
  if (process.env.NODE_ENV === "development") {
    // eslint-disable-next-line no-console
    console.debug(...messages);
  }
}

async function handleInstall(_: ExtendableEvent) {
  debug("Service worker installed");
}

async function handleActivate(_: ExtendableEvent) {
  debug("Service worker activated");
}

async function handleFetch(event: FetchEvent): Promise<Response> {
  const url = new URL(event.request.url);

  if (isAssetRequest(event.request)) {
    const cached = await caches.match(event.request, {
      cacheName: ASSET_CACHE,
      ignoreVary: true,
      ignoreSearch: true,
    });
    if (cached) {
      debug("Serving asset from cache", url.pathname);
      return cached;
    }

    debug("Serving asset from network", url.pathname);
    const response = await fetch(event.request);
    if (response.status === 200) {
      const cache = await caches.open(ASSET_CACHE);
      await cache.put(event.request, response.clone());
    }
    return response;
  }

  if (isLoaderRequest(event.request)) {
    try {
      debug("Serving data from network", url.pathname + url.search);
      const response = await fetch(event.request.clone());
      const cache = await caches.open(DATA_CACHE);
      await cache.put(event.request, response.clone());
      return response;
    } catch (error) {
      debug(
        "Serving data from network failed, falling back to cache",
        url.pathname + url.search
      );
      const response = await caches.match(event.request);
      if (response) {
        response.headers.set("X-Remix-Worker", "yes");
        return response;
      }

      return json(
        { message: "Network Error" },
        {
          status: 500,
          headers: { "X-Remix-Catch": "yes", "X-Remix-Worker": "yes" },
        }
      );
    }
  }

  if (isDocumentGetRequest(event.request)) {
    try {
      debug("Serving document from network", url.pathname);
      const response = await fetch(event.request);
      const cache = await caches.open(DOCUMENT_CACHE);
      await cache.put(event.request, response.clone());
      return response;
    } catch (error) {
      debug(
        "Serving document from network failed, falling back to cache",
        url.pathname
      );
      const response = await caches.match(event.request);
      if (response) {
        return response;
      }
      throw error;
    }
  }

  return fetch(event.request.clone());
}

function isMethod(request: Request, methods: string[]) {
  return methods.includes(request.method.toLowerCase());
}

function isAssetRequest(request: Request) {
  return (
    isMethod(request, ["get"]) &&
    STATIC_ASSETS.some((publicPath) => request.url.startsWith(publicPath))
  );
}

function isLoaderRequest(request: Request) {
  const url = new URL(request.url);
  return isMethod(request, ["get"]) && url.searchParams.get("_data");
}

function isDocumentGetRequest(request: Request) {
  return isMethod(request, ["get"]) && request.mode === "navigate";
}

self.addEventListener("install", (event) => {
  event.waitUntil(handleInstall(event).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(handleActivate(event).then(() => self.clients.claim()));
});

self.addEventListener("fetch", (event) => {
  event.respondWith(
    (async () => {
      const result = {} as
        | { error: unknown; response: Response }
        | { error: undefined; response: Response };
      try {
        result.response = await handleFetch(event);
      } catch (error) {
        result.error = error;
      }

      return appHandleFetch(event, result);
    })()
  );
});

async function appHandleFetch(
  _: FetchEvent,
  {
    error,
    response,
  }:
    | { error: unknown; response: Response }
    | { error: undefined; response: Response }
): Promise<Response> {
  return response;
}
