import { FaChevronDown } from "react-icons/fa";
import type { BoxProps } from "@chakra-ui/react";
import {
  Box,
  Button,
  Popover,
  PopoverArrow,
  PopoverBody,
  PopoverCloseButton,
  PopoverContent,
  PopoverTrigger,
  Radio,
  RadioGroup,
  Stack,
  Text,
} from "@chakra-ui/react";

import type { OptionItem } from "./types";

export type PbiSelectProps = {
  title: string;
  placeholder: string;
  className?: string;
  value: OptionItem;
  items: OptionItem[];
  boxProps?: BoxProps;
  onChange: (value: string) => void;
};

const PbiSelect = ({
  title,
  placeholder,
  value,
  onChange,
  items,
  boxProps = {},
}: PbiSelectProps) => {
  return (
    <Box mt={2} {...boxProps}>
      <Text>{title}</Text>
      <Popover>
        <PopoverTrigger>
          <Button
            variant="outline"
            size="sm"
            w="100%"
            rightIcon={<FaChevronDown />}
          >
            {value?.label || placeholder}
          </Button>
        </PopoverTrigger>
        <PopoverContent>
          <PopoverArrow />
          <PopoverCloseButton />
          <PopoverBody maxH="400px" overflowY="auto">
            <RadioGroup onChange={onChange} value={value?.value}>
              <Stack direction="column">
                {items.map((item) => (
                  <Radio
                    key={item.value}
                    value={item.value}
                    checked={item.value === value.value}
                  >
                    {item.label}
                  </Radio>
                ))}
              </Stack>
            </RadioGroup>
          </PopoverBody>
        </PopoverContent>
      </Popover>
    </Box>
  );
};

export default PbiSelect;
