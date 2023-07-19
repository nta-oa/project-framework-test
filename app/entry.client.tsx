import { startTransition, StrictMode } from "react";
import { RemixBrowser } from "@remix-run/react";
import i18next from "i18next";
import LanguageDetector from "i18next-browser-languagedetector";
import I18nChainedBackend from "i18next-chained-backend";
import I18nHttpBackend from "i18next-http-backend";
import I18nLocalStorageBackend from "i18next-localstorage-backend";
import { hydrateRoot } from "react-dom/client";
import { I18nextProvider, initReactI18next } from "react-i18next";
import { getInitialNamespaces } from "remix-i18next";
import { CacheProvider } from "@emotion/react";
import createEmotionCache from "@emotion/cache";
import ms from "ms";

import i18n from "config/i18n.json";
import type { NodeEnv } from "./types/config";

declare global {
  interface Window {
    env: {
      NODE_ENV: NodeEnv;
    };
  }
}

/**
 * Initialize i18next and hydrate Remix application
 * translations are loaded from /static/ and cached in localStorage for 1d
 */
(async () => {
  await i18next
    .use(initReactI18next)
    .use(LanguageDetector)
    .use(I18nChainedBackend)
    .init({
      ...i18n,
      ns: getInitialNamespaces(),
      detection: {
        order: ["htmlTag", "cookie", "localstorage"],
      },
      backend: {
        backends: [I18nLocalStorageBackend, I18nHttpBackend],
        backendOptions: [
          {
            expirationTime: ms("1d"),
          },
          {
            loadPath: "/static/locales/{{lng}}/{{ns}}.json",
          },
        ],
      },
    });

  const emotionCache = createEmotionCache({ key: "css" });

  const hydrate = () => {
    startTransition(() => {
      hydrateRoot(
        document,
        <StrictMode>
          <CacheProvider value={emotionCache}>
            <I18nextProvider i18n={i18next}>
              <RemixBrowser />
            </I18nextProvider>
          </CacheProvider>
        </StrictMode>
      );
    });
  };

  // Using requestIdleCallback for better performance if available, otherwise fallback to setTimeout
  if (window.requestIdleCallback) {
    window.requestIdleCallback(hydrate);
  } else {
    // Safari doesn't support requestIdleCallback
    // https://caniuse.com/requestidlecallback
    window.setTimeout(hydrate, 1);
  }

  if ("serviceWorker" in navigator && window.env.NODE_ENV === "production") {
    // Use the window load event to keep the page load performant
    navigator.serviceWorker
      .register("/sw.js")
      .then(() => navigator.serviceWorker.ready)
      .catch((error) => {
        // eslint-disable-next-line no-console
        console.error("Service worker registration failed", error);
      });
  }
})();
