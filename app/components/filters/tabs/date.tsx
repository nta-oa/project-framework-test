import { Card, CardBody, Flex } from "@chakra-ui/react";
import { useTranslation } from "react-i18next";

import PbiSelect from "~/components/form/pbi-select";
import { useFilter } from "~/context/filters";
import { useDateItems } from "~/context/filters/hooks/date";
import { dateFilters } from "~/types/filters";

const DateTab = () => {
  const { t } = useTranslation("dashboard");
  const { dispatch, ...state } = useFilter();
  const dateItems = useDateItems();

  return (
    <Card mt={3}>
      <CardBody
        as={Flex}
        direction="row"
        justifyContent="space-between"
        gap={6}
      >
        {dateFilters.map((name, index) => {
          const { selectedValues, items } = state[name];

          const values = items.filter(({ value }) =>
            selectedValues.includes(value)
          );

          return (
            <PbiSelect
              key={index}
              title={t(name)}
              items={dateItems[name]}
              value={values[0]}
              onChange={(value) => {
                dispatch({
                  type: "set_single_filter",
                  payload: [name, value],
                });
              }}
              placeholder={t("Select filter-name", {
                name: t(name),
              })}
              boxProps={{
                flex: 1,
              }}
            />
          );
        })}
      </CardBody>
    </Card>
  );
};

export default DateTab;
