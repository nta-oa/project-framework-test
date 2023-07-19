import { useTranslation } from "react-i18next";
import { Box, Flex, Grid, GridItem, Heading } from "@chakra-ui/react";

import { NavSubMenuList } from "~/components/homepage/nav-menu";
import { SocialLinks } from "~/components/homepage/social-links";

export default function HomePage() {
  const { t } = useTranslation("common");

  return (
    <Grid
      templateColumns="10fr 1fr"
      bgGradient="linear(to-tr, rgm.purple.500, rgm.purple.600, rgm.purple.600, rgm.purple.700)"
      gap={4}
      display={["flex", "flex", "grid"]}
      flexDirection={["column-reverse", "column-reverse", "unset"]}
      minH={["100%", "100%", "100%", "100vh"]}
    >
      <Flex
        height="100%"
        display="flex"
        flexDirection="column"
        justifyContent="space-around"
      >
        <Box
          p={6}
          display="flex"
          flexDirection="column"
          textAlign={["center", "center", "center", "left"]}
        >
          <Heading as="h1" size="2xl" color="white">
            {t("WELCOME TO VALUE COCKPIT")}
          </Heading>
          <Heading as="h2" size="lg" color="white">
            {t("ANALYTICS PLATFORM")}
          </Heading>
        </Box>
        <Grid
          flex={1}
          p={6}
          maxH={["auto", "auto", "auto", "auto", "60rem"]}
          maxW="200rem"
          minW="70%"
          alignSelf={["unset", "unset", "unset", "unset", "unset", "center"]}
          templateRows={[
            "repeat(9, 1fr)",
            "repeat(9, 1fr)",
            "repeat(5, 1fr)",
            "repeat(5, 1fr)",
            "repeat(3, 1fr)",
          ]}
          templateColumns={[
            "unset",
            "unset",
            "repeat(6, 1fr)",
            "repeat(6, 1fr)",
            "repeat(9, 1fr)",
          ]}
          gap={4}
        >
          <NavSubMenuList />
        </Grid>
      </Flex>
      <GridItem bgColor="rgm.purple.100" textAlign={"center"} overflow="hidden">
        <Box
          pt="10px"
          pb="10px"
          display={["flex", "flex", "unset"]}
          justifyContent={["center", "center", "left"]}
        >
          <SocialLinks />
        </Box>
      </GridItem>
    </Grid>
  );
}
