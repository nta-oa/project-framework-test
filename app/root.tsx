import type { LinksFunction, MetaFunction } from "@remix-run/node";
import { json } from "@remix-run/node";
import {
  Links,
  LiveReload,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
  useCatch,
  useLoaderData,
} from "@remix-run/react";
import { Box, ChakraProvider, Heading } from "@chakra-ui/react";
import { useTranslation } from "react-i18next";
import { useChangeLanguage } from "remix-i18next";
import { unauthorized } from "remix-utils";

import pkg from "pkg.json";
import icons from "config/icons.json";
import type { RemixFunction } from "~/types/context";
import { remixI18next } from "~/services/i18n.server";
import type { NodeEnv } from "~/types/config";
import rootCss from "~/styles/root.css";
import theme from "~/styles/theme";

export const links: LinksFunction = () => {
  return [
    { rel: "manifest", href: "/static/app.webmanifest" },
    { rel: "stylesheet", href: rootCss },
    ...icons,
  ];
};

export const meta: MetaFunction = () => ({
  title: pkg.name,
  description: pkg.description,
  charSet: "utf-8",
  viewport: "width=device-width,initial-scale=1",
  "theme-color": pkg.themeColor,

  "apple-mobile-web-app-title": pkg.name,
  "apple-mobile-web-app-capable": "yes",
  "apple-mobile-web-app-status-bar-style": "default",
});

type LoaderData = {
  locale: string;
  env: {
    NODE_ENV: NodeEnv;
  };
};

export const loader: RemixFunction = async ({
  request,
  context: { config, user },
}) => {
  const locale = await remixI18next.getLocale(request);

  if (!user) {
    throw unauthorized("no user");
  }

  return json<LoaderData>({
    locale,
    env: {
      NODE_ENV: config.nodeEnv,
    },
  });
};

export const handle = {
  i18n: ["common"],
};

export default function Root() {
  const { locale, env } = useLoaderData<LoaderData>();
  const { i18n } = useTranslation();
  useChangeLanguage(locale);

  const envScript = {
    __html: "window.env = " + JSON.stringify(env),
  };

  return (
    <html lang={locale} dir={i18n.dir()} className="h-full">
      <head>
        <Meta />
        <Links />
        <noscript>
          <style>{".js-only { display: none }"}</style>
        </noscript>
      </head>
      <body>
        <ChakraProvider theme={theme}>
          <Box w="100%" h="100%" bg="bg">
            <Outlet />
            <ScrollRestoration />
            <script dangerouslySetInnerHTML={envScript} />
            <Scripts />
            <LiveReload />
          </Box>
        </ChakraProvider>
      </body>
    </html>
  );
}

export const CatchBoundary = () => {
  const caught = useCatch();
  const { i18n } = useTranslation();

  return (
    <html lang={i18n.language} dir={i18n.dir()}>
      <head>
        <title>Oops!</title>
        <Meta />
        <Links />
      </head>
      <body>
        <ChakraProvider theme={theme}>
          <Heading as="h1">
            {caught.status} {caught.data}
          </Heading>
        </ChakraProvider>
        <Scripts />
      </body>
    </html>
  );
};
