import { Flex } from "@chakra-ui/react";
import { Outlet } from "@remix-run/react";
import { useMemo } from "react";
import { useTranslation } from "react-i18next";

import DashboardHeader from "./_components/dashboard-header";

export default function PnLPage() {
  const { t } = useTranslation("pnl");

  const tabData = useMemo(() => {
    return [
      {
        label: t("Summary"),
        to: "/pnl/summary",
      },
      {
        label: t("Trade Terms"),
        to: "/pnl/trade-terms",
      },
      {
        label: t("Minorations"),
        to: "/pnl/minorations",
      },
    ];
  }, [t]);

  return (
    <Flex flex="1" m={5} flexDirection="column">
      <DashboardHeader tabData={tabData} />
      <Outlet />
    </Flex>
  );
}
