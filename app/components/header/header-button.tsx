import type { IconButtonProps } from "@chakra-ui/react";
import { IconButton, Icon } from "@chakra-ui/react";
import type { IconType } from "react-icons";

export type HeaderButtonProps = Omit<IconButtonProps, "icon"> & {
  icon: IconType;
  to?: string;
};

const size = ["1rem", "1rem", "2rem"];

const HeaderButton = ({ icon, ...props }: HeaderButtonProps) => {
  return (
    <IconButton
      {...props}
      icon={<Icon as={icon} color="button.color" h={size} w={size} />}
      px={[2, 2, 4]}
      bg="button.bg"
      _hover={{
        bg: "button.hover.bg",
      }}
    />
  );
};

export default HeaderButton;
