import { json, redirect } from "@remix-run/node";
import { Outlet, useLoaderData, useLocation } from "@remix-run/react";
import { Container, Flex } from "@chakra-ui/react";
import { useTranslation } from "react-i18next";

import { FilterProvider } from "~/context/filters/provider";
import Header from "~/components/header";
import type { RemixFunction } from "~/types/context";
import {
  getCategoryFilters,
  getGeoFilters,
  getDateFilters,
} from "~/routes/dashboard/_services/filters.server";

export const loader: RemixFunction = async ({
  context: { data, user },
  request,
}) => {
  const url = new URL(request.url);

  const year = url.searchParams.get("year");
  const month = url.searchParams.get("month");

  if (!year && !month) {
    const date = new Date();
    const pruneMonth = date.getMonth() + 1;
    const year = date.getFullYear().toString();
    const month =
      pruneMonth.toString().length === 1
        ? `0${pruneMonth}`
        : pruneMonth.toString();

    const searchParams = new URLSearchParams();
    searchParams.append("year", year);
    searchParams.append("month", month);

    return redirect(`${request.url}?${searchParams.toString()}`, {
      headers: {
        "Access-Control-Allow-Origin": "*",
      },
    });
  }

  const [geography, date, category] = await Promise.all([
    getGeoFilters({ data, user }),
    getDateFilters({ data }),
    getCategoryFilters({ data, user }),
  ]);

  if (year && month) {
    date.year.selectedValues = [year];
    date.month.selectedValues = [month];
  }

  return json({
    filters: {
      ...geography,
      ...date,
      ...category,
    },
  });
};

export const handle = {
  i18n: ["dashboard"],
};

export default function DashboardPage() {
  const { filters } = useLoaderData<typeof loader>();
  const { t } = useTranslation("dashboard");
  const location = useLocation();

  return (
    <FilterProvider value={filters}>
      <Flex flexDirection="column" h="100vh" w="100%">
        <Header title={t(location.pathname)} />
        <Container
          as="main"
          maxW="container.xxl"
          bg="bg"
          flex="1"
          paddingX={[0, "1em", "1em", "2em"]}
        >
          <Outlet />
        </Container>
      </Flex>
    </FilterProvider>
  );
}
