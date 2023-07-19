import {
  Button,
  Flex,
  Heading,
  IconButton,
  TabList,
  TabPanel,
  TabPanels,
  Tabs,
} from "@chakra-ui/react";
import { useTranslation } from "react-i18next";
import { RxCalendar } from "react-icons/rx";
import { IoEarth } from "react-icons/io5";
import { MdFace2 } from "react-icons/md";
import { TfiRulerPencil, TfiClose } from "react-icons/tfi";
import { AiOutlineEuro, AiOutlineShoppingCart } from "react-icons/ai";

import { useFilter } from "~/context/filters";
import TabButton from "~/components/tab-button";
import CategoryTab from "./tabs/category";
import GeographyTab from "./tabs/geography";
import DateTab from "./tabs/date";
import FilterSummary from "./summary";
import { objectEntries } from "ts-extras";

export type FiltersProps = {
  onClose: () => void;
  onSubmit: (values: Record<string, string[]>) => void;
};

const tabsData = [
  {
    icon: RxCalendar,
    label: "Date",
    content: <DateTab />,
  },
  {
    icon: IoEarth,
    label: "Geography",
    content: <GeographyTab />,
  },
  {
    icon: MdFace2,
    label: "Category",
    content: <CategoryTab />,
  },
  {
    icon: TfiRulerPencil,
    label: "Product",
    content: <p>Product</p>,
  },
  {
    icon: AiOutlineShoppingCart,
    label: "Customer",
    content: <p>Customer</p>,
  },
  {
    icon: AiOutlineEuro,
    label: "Scenarios",
    content: <p>Scenario</p>,
  },
];

const Filters = ({ onClose, onSubmit }: FiltersProps) => {
  const { t } = useTranslation("dashboard");
  const { dispatch, ...state } = useFilter();

  const handleResetAll = () => {
    dispatch({ type: "reset_all" });
  };

  const handleSubmit = () => {
    const filterValues = objectEntries(state).reduce(
      (acc, [key, { selectedValues }]) => {
        if (!!selectedValues && selectedValues?.length === 0) {
          return acc;
        }

        return {
          ...acc,
          [key]: selectedValues,
        };
      },
      {}
    );

    onSubmit(filterValues);
  };

  return (
    <Flex h="100vh" direction="column" p={[2, 6, 8]} overflow="auto">
      <Flex direction="row" justifyContent="space-between" p={2}>
        <Heading>{t("Filters")}</Heading>
        <IconButton
          colorScheme="purple"
          alignSelf="end"
          aria-label="close filters"
          variant="unstyled"
          onClick={onClose}
        >
          <TfiClose size="2em" color="purple" />
        </IconButton>
      </Flex>
      <Tabs p={2}>
        <TabList
          flexDir="row"
          justifySelf="center"
          overflowX="auto"
          overflowY="hidden"
        >
          {tabsData.map(({ label, icon }) => (
            <TabButton
              key={label}
              label={label}
              icon={icon}
              colorScheme="purple"
              flex="1"
            />
          ))}
        </TabList>

        <TabPanels>
          {tabsData.map(({ content, label }) => (
            <TabPanel key={label}>{content}</TabPanel>
          ))}
        </TabPanels>
      </Tabs>
      <FilterSummary />
      <Flex mt={2} direction="row" gap={2} justifyContent="end">
        <Button variant="outline" colorScheme="purple" onClick={handleResetAll}>
          {t("Reset filter")}
        </Button>
        <Button variant="solid" colorScheme="purple" onClick={handleSubmit}>
          {t("Apply all")}
        </Button>
      </Flex>
    </Flex>
  );
};

export default Filters;
