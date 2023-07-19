import { Flex, Text, Icon } from "@chakra-ui/react";
import { FaCaretUp, FaCaretDown } from "react-icons/fa";

export type KpiValueProps = {
  type: "percent" | "pt";
  value: string;
};

const KpiValue = ({ value, type }: KpiValueProps) => {
  const isPositive = !value.includes("-");

  switch (type) {
    case "pt":
      const icon = isPositive ? FaCaretUp : FaCaretDown;
      const arrowColor = isPositive ? "#64b178" : "#f26e5f";

      return (
        <Flex as="span" flexDirection="row" gap="2">
          <Icon
            as={icon}
            color={arrowColor}
            alignSelf="center"
            fontSize="2xl"
          />
          <Text alignSelf="center">{value}</Text>
        </Flex>
      );
    case "percent":
      const percentColor = isPositive ? "#3271cc" : "#faab32";

      return <Text color={percentColor}>{value}</Text>;
  }
};

export default KpiValue;
