import type { BoxProps } from "@chakra-ui/react";
import {
  Box,
  Button,
  Checkbox,
  Popover,
  PopoverArrow,
  PopoverBody,
  PopoverCloseButton,
  PopoverContent,
  PopoverTrigger,
  Stack,
  Text,
} from "@chakra-ui/react";
import { useCallback, useMemo } from "react";
import { FaChevronDown } from "react-icons/fa";
import { useToggle } from "usehooks-ts";

import type { OptionItem } from "./types";

export type PbiMultiSelectProps = {
  title: string;
  placeholder?: string;
  allLabel: string;
  values: OptionItem[];
  items: OptionItem[];
  boxProps?: BoxProps;
  onChange: (values: string[]) => void;
};

const PbiMultiSelect = ({
  title,
  placeholder,
  allLabel,
  values,
  onChange,
  items,
  boxProps = {},
}: PbiMultiSelectProps) => {
  const [all, toggleAll] = useToggle(false);

  const displayValue = useMemo(() => {
    if (all || values.length === 0) {
      return allLabel;
    }

    return values
      .map(({ label }) => label)
      .slice(0, 2)
      .join(", ");
  }, [all, allLabel, values]);

  const handleChange = useCallback(
    (val: string) => {
      if (values.some(({ value }) => val === value)) {
        onChange(
          values.filter(({ value }) => val !== value).map(({ value }) => value)
        );
      } else {
        onChange([...values.map(({ value }) => value), val]);
      }
    },
    [onChange, values]
  );

  const handleToggleAll = useCallback(() => {
    toggleAll();

    if (!all) {
      onChange(items.map(({ value }) => value));
    } else {
      onChange([]);
    }
  }, [all, items, onChange, toggleAll]);

  return (
    <Box mt={2} {...boxProps}>
      <Text>{title}</Text>
      <Popover>
        <PopoverTrigger>
          <Button
            variant="outline"
            w="100%"
            size="sm"
            rightIcon={<FaChevronDown />}
          >
            {displayValue || placeholder}
          </Button>
        </PopoverTrigger>

        <PopoverContent>
          <PopoverArrow />
          <PopoverCloseButton />
          <PopoverBody>
            <Checkbox
              isChecked={all}
              isIndeterminate={values.some(Boolean) && !all}
              onChange={handleToggleAll}
            >
              {allLabel}
            </Checkbox>
            <Stack pl={6} mt={1} spacing={1} maxH="200px" overflowY="auto">
              {items.map((item) => (
                <Checkbox
                  key={item.value}
                  value={item.value}
                  isChecked={values.some(({ value }) => value === item.value)}
                  onChange={() => handleChange(item.value)}
                >
                  {item.label}
                </Checkbox>
              ))}
            </Stack>
          </PopoverBody>
        </PopoverContent>
      </Popover>
    </Box>
  );
};

export default PbiMultiSelect;
