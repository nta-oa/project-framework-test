import {
  Card,
  CardBody,
  CardHeader,
  Flex,
  Heading,
  Table,
  Tbody,
  Text,
  Tr,
  Td,
} from "@chakra-ui/react";
import { useTranslation } from "react-i18next";
import { objectEntries } from "ts-extras";

import { useFilter } from "~/context/filters";

const FilterSummary = () => {
  const { t } = useTranslation("dashboard");
  const { dispatch, ...state } = useFilter();

  return (
    <Card w="100%">
      <CardHeader
        backgroundColor="rgb(245, 235, 251, 0.5)"
        border="solid 0.5px purple"
      >
        <Heading as="h4" size="md" mb={1} textAlign="center">
          {t("Selected Filters")}
        </Heading>
      </CardHeader>
      <CardBody
        borderRight="solid 0.5px purple"
        borderLeft="solid 0.5px purple"
        borderBottom="solid 0.5px purple"
      >
        <Table
          variant="unstyled"
          colorScheme="purple"
          height="150px"
          overflowY="auto"
          display="block"
        >
          <Tbody>
            {objectEntries(state)
              .filter(([_, { selectedValues }]) => selectedValues?.length > 0)
              .map(([key, filter]) => (
                <Tr key={key}>
                  <Td borderRight="solid 1px purple">{t(key)}</Td>
                  <Td>
                    {Array.isArray(filter.selectedValues) ? (
                      <Flex direction="column" gap={0.5}>
                        {filter.selectedValues.map((val, index) => {
                          const item = filter.items.find(
                            ({ value }) => val === value
                          );

                          return <Text key={index}>{item?.label || val}</Text>;
                        })}
                      </Flex>
                    ) : (
                      <Text>{filter.selectedValues}</Text>
                    )}
                  </Td>
                </Tr>
              ))}
          </Tbody>
        </Table>
      </CardBody>
    </Card>
  );
};

export default FilterSummary;
