import { RemixServer } from "@remix-run/react";
import type { EntryContext } from "@remix-run/node";
import { Response } from "@remix-run/node";
import { createInstance } from "i18next";
import I18nFsBackend from "i18next-fs-backend";
import { renderToPipeableStream } from "react-dom/server";
import { I18nextProvider, initReactI18next } from "react-i18next";
import isbot from "isbot";
import ms from "ms";
import { PassThrough } from "node:stream";
import createEmotionCache from "@emotion/cache";
import createEmotionServer from "@emotion/server/create-instance";

import i18nConfig from "config/i18n.json";
import serverConfig from "config/server.json";
import { remixI18next } from "~/services/i18n.server";

/**
 * Handle incoming requests by rendering the Remix application and returning the result as an HTTP response.
 *
 * @param request - The incoming request to handle.
 * @param status - The HTTP status code to set in the response.
 * @param headers - The HTTP headers to set in the response.
 * @param context - The Remix context for the incoming request.
 * @returns A Promise that resolves to an HTTP Response object.
 */
export default async function handleRequest(
  request: Request,
  status: number,
  headers: Headers,
  context: EntryContext
) {
  // Initialize the i18next instance and Emotion cache for this request.
  const i18nInstance = createInstance();
  const emotionCache = createEmotionCache({ key: "css" });

  headers.set("Access-Control-Allow-Origin", "*");

  // Load translations and initialize i18next with them.
  await i18nInstance
    .use(initReactI18next)
    .use(I18nFsBackend)
    .init({
      ...i18nConfig,
      backend: {
        loadPath: "./public/locales/{{lng}}/{{ns}}.json",
      },
      lng: await remixI18next.getLocale(request),
      ns: remixI18next.getRouteNamespaces(context),
    });

  // Determine the callback name to use based on the user-agent header.
  const callbackName = isbot(request.headers.get("user-agent"))
    ? "onAllReady"
    : "onShellReady";

  return new Promise((resolve, reject) => {
    let didError = false;

    // Use `renderToPipeableStream` to render the Remix application to a pipeable stream.
    const { pipe, abort } = renderToPipeableStream(
      <I18nextProvider i18n={i18nInstance}>
        <RemixServer context={context} url={request.url} />
      </I18nextProvider>,
      {
        [callbackName]: () => {
          // Create a new PassThrough stream for the response body.
          const body = new PassThrough();

          // Create an Emotion server instance and render the styles to a node stream and pipe it into the response body..
          const emotionServer = createEmotionServer(emotionCache);
          const bodyWithStyles = emotionServer.renderStylesToNodeStream();
          body.pipe(bodyWithStyles);

          // Set the response headers and resolve the Promise with an HTTP Response object.
          headers.set("Content-Type", "text/html");
          resolve(
            new Response(body, {
              headers,
              status: didError ? 500 : status,
            })
          );

          // Pipe the response body into the original stream.
          pipe(body);
        },
        onShellError: (err: unknown) => {
          reject(err);
        },
        onError: (error: unknown) => {
          didError = true;
          // eslint-disable-next-line no-console
          console.error(error);
        },
      }
    );

    // Abort the rendering after a timeout, in case it takes too long.
    setTimeout(abort, ms(serverConfig.abortDelay));
  });
}
