import { Card, CardBody, Flex } from "@chakra-ui/react";
import { useTranslation } from "react-i18next";

import PbiMultiSelect from "~/components/form/pbi-multi-select";
import { useFilter, useCategoryFilters } from "~/context/filters";
import { categoryFilters } from "~/types/filters";

const CategoryTab = () => {
  const { t } = useTranslation("dashboard");
  const { dispatch, ...state } = useFilter();
  const filterItems = useCategoryFilters();

  return (
    <Card mt={3}>
      <CardBody
        as={Flex}
        direction={["column", "column", "row", "row"]}
        justifyContent="space-between"
        flexWrap="wrap"
        gap={[0, 2, 4, 6]}
      >
        {categoryFilters.map((name, index) => {
          const { selectedValues, items } = state[name];

          const values = items.filter(({ value }) =>
            selectedValues.includes(value)
          );

          return (
            <PbiMultiSelect
              key={index}
              title={t(name)}
              items={filterItems[name]}
              values={values}
              allLabel={t("All")}
              onChange={(values) => {
                dispatch({
                  type: "set_multiple_filter",
                  payload: [name, values],
                });
              }}
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

export default CategoryTab;
