import { Flex, Heading, Tab, TabList, Tabs } from "@chakra-ui/react";
import { Link, useLocation } from "@remix-run/react";
import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import { useFilter } from "~/context/filters";

export type DashboardHeaderProps = {
  tabData: { label: string; to: string }[];
};

const DashboardHeader = ({ tabData }: DashboardHeaderProps) => {
  const { month, year } = useFilter();
  const location = useLocation();
  const { t } = useTranslation("dashboard");

  const tabIndex = useMemo(() => {
    const activeTab = tabData.find(({ to }) => location.pathname === to);

    if (activeTab) {
      return tabData.indexOf(activeTab);
    }
  }, [location.pathname, tabData]);

  return (
    <Flex
      as="header"
      flexDirection={["column", "column", "row", "row"]}
      justifyContent={[
        "flex-start",
        "flex-start",
        "space-between",
        "space-between",
      ]}
      gap={[5, 5, 0, 0]}
      mb="2em"
    >
      <Flex
        flexDirection="column"
        justifyContent="space-between"
        alignSelf={["flex-start", "flex-start", "center", "center"]}
        gap={5}
      >
        <Heading
          as="h2"
          fontSize={["md", "lg", "xl", "2xl"]}
          fontWeight="bolder"
        >
          {t("Displaying informations", {
            month: month.selectedValues[0],
            year: year.selectedValues[0],
          })}
        </Heading>
        <Heading as="h3" fontSize={["md", "md", "lg"]} fontWeight="thin">
          {t("Scope of data: ...", {})}
        </Heading>
      </Flex>
      <Tabs
        as="nav"
        index={tabIndex}
        variant="soft-rounded"
        colorScheme="gray"
        alignSelf="center"
      >
        <TabList>
          {tabData.map((tab, index) => (
            <Tab
              key={index}
              as={Link}
              to={"/dashboard" + tab.to}
              borderColor="none"
              fontSize={["sm", "md", "lg"]}
            >
              {tab.label}
            </Tab>
          ))}
        </TabList>
      </Tabs>
    </Flex>
  );
};

export default DashboardHeader;
