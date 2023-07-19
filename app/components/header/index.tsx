import { Flex, Heading, HStack } from "@chakra-ui/react";
import { Link, useLocation, useNavigate } from "@remix-run/react";
import { FaBinoculars, FaFilter, FaHome } from "react-icons/fa";

import Filters from "../filters";
import HeaderButton from "./header-button";
import HeaderDrawer from "./header-drawer";

export type HeaderProps = {
  title: string;
};

const Header = ({ title }: HeaderProps) => {
  const location = useLocation();
  const navigate = useNavigate();

  const handleFilterUpdate = (filters: Record<string, string[]>) => {
    const searchParams = new URLSearchParams();

    for (const key in filters) {
      filters[key].forEach((value) => {
        searchParams.append(key, value);
      });
    }

    navigate({
      search: searchParams.toString(),
      pathname: location.pathname,
    });
  };

  return (
    <Flex
      as="header"
      bgGradient="linear(to-b, header.bg.0, header.bg.1)"
      h={16}
      px={[1, 2, 3, 4]}
      alignItems="center"
      justifyContent="space-between"
    >
      <HStack spacing={8}>
        <HeaderButton as={Link} icon={FaHome} to="/" aria-label="Home link" />
        <Heading
          as="h1"
          color="button.color"
          fontSize={["md", "lg", "3xl", "3xl", "3xl"]}
        >
          {title}
        </Heading>
      </HStack>
      <HStack>
        <HeaderButton icon={FaBinoculars} aria-label="filter group by" />
        <HeaderDrawer
          icon={FaFilter}
          size={["full", "full", "xl", "xl"]}
          placement="right"
          aria-label="filter toggle button"
          renderContent={({ onClose }) => (
            <Filters onClose={onClose} onSubmit={handleFilterUpdate} />
          )}
        />
      </HStack>
    </Flex>
  );
};

export default Header;
