import { createCookie } from "@remix-run/node";
import { RemixI18Next } from "remix-i18next";

import i18nConfig from "config/i18n.json";

export const remixI18next = new RemixI18Next({
  detection: {
    supportedLanguages: i18nConfig.supportedLngs,
    fallbackLanguage: i18nConfig.fallbackLng,
    cookie: createCookie("i18n", {
      sameSite: "lax",
      path: "/",
    }),
  },
});
