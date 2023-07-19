import type { ButtonProps } from "@chakra-ui/react";
import {
  Button,
  Flex,
  Text,
  Icon,
  useMultiStyleConfig,
  useTab,
} from "@chakra-ui/react";
import { forwardRef } from "react";
import type { IconType } from "react-icons";

export type TabButtonProps = {
  icon?: IconType;
  label: string;
} & ButtonProps;

const TabButton = forwardRef<HTMLButtonElement, TabButtonProps>(
  ({ icon, label, ...props }, ref) => {
    const tabProps = useTab({ ...props, ref });
    const styles = useMultiStyleConfig("Tabs", tabProps);

    return (
      <Button
        mt={2}
        h={16}
        size="lg"
        isActive={!!tabProps["aria-selected"]}
        __css={styles.tab}
        {...tabProps}
      >
        <Flex direction="column" alignItems="center">
          {icon && <Icon size="2em" as={icon} />}
          <Text mt="5px">{label}</Text>
        </Flex>
      </Button>
    );
  }
);

TabButton.displayName = "TabButton";

export default TabButton;
