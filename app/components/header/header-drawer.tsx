import type { DrawerProps } from "@chakra-ui/react";
import {
  useDisclosure,
  Drawer,
  DrawerContent,
  DrawerOverlay,
} from "@chakra-ui/react";

import type { HeaderButtonProps } from "./header-button";
import HeaderButton from "./header-button";

type RenderProps = {
  onClose: () => void;
};

export type HeaderDrawerProps = HeaderButtonProps & {
  size: DrawerProps["size"];
  placement: DrawerProps["placement"];
  renderContent: (props: RenderProps) => JSX.Element;
};

const HeaderDrawer = ({
  placement,
  size,
  renderContent,
  ...headerProps
}: HeaderDrawerProps) => {
  const { isOpen, onOpen, onClose } = useDisclosure();

  return (
    <>
      <HeaderButton {...headerProps} onClick={onOpen} />
      <Drawer
        isOpen={isOpen}
        placement={placement}
        onClose={onClose}
        size={size}
      >
        <DrawerOverlay />
        <DrawerContent>{renderContent({ onClose })}</DrawerContent>
      </Drawer>
    </>
  );
};

export default HeaderDrawer;
