import {
  Button,
  GridItem,
  Heading,
  Link,
  Stack,
  Text,
  Tooltip,
} from "@chakra-ui/react";
import { useTranslation } from "react-i18next";
import type { navSubMenuLinkType } from "./data";
import { navSubMenuData } from "./data";

const NavMenuLink = (props: { link: navSubMenuLinkType }) => {
  const { t } = useTranslation("common");
  return (
    <Link href={props.link.url} isExternal={props.link.isExternal} w="90%">
      <Tooltip
        label={t(
          props.link.description ??
            `${t("Click to go to")} ${t(props.link.title)}`
        )}
        isDisabled={props.link.isDisabled}
      >
        <Button
          bgColor="rgm.purple.400"
          p={0}
          w="100%"
          h={["25px", "30px", "35px"]}
          isDisabled={props.link.isDisabled}
          borderRadius="sm"
        >
          <Text fontSize={["xs", "xs", "sm", "lg"]}>{t(props.link.title)}</Text>
        </Button>
      </Tooltip>
    </Link>
  );
};
export const NavSubMenuList = () => {
  const { t } = useTranslation("common");
  return (
    <>
      {navSubMenuData.map((items, index) => {
        return (
          <GridItem
            key={"sub-menu-" + index}
            p={["0.2rem", "0.2rem", "0.2rem", "0.2rem", "1rem"]}
            maxH="17rem"
            colSpan={3}
            bg="rgm.purple.transparent"
            borderWidth="1px"
            borderRadius="md"
            borderColor="rgm.purple.300"
            transition={["unset", "unset", "unset", "0.50s"]}
            _hover={{ transform: ["none", "none", "none", "scale(1.04)"] }}
          >
            <Stack
              spacing={4}
              pt="15px"
              pb="15px"
              height="100%"
              direction="column"
              align="center"
              justifyContent="center"
            >
              <Heading as="h3" size="md" textAlign="center" p={1} color="white">
                {t(items.title)}
              </Heading>

              {items.active ? (
                items.links.map((item, index) => (
                  <NavMenuLink link={item} key={index} />
                ))
              ) : (
                <Button
                  bgColor="rgm.purple.400"
                  w="90%"
                  h="10em"
                  borderRadius="md"
                  isDisabled={true}
                >
                  {t("COMING SOON")}
                </Button>
              )}
            </Stack>
          </GridItem>
        );
      })}
    </>
  );
};
