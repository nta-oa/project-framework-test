import { IconButton, Link } from "@chakra-ui/react";
import { socialLinksData } from "./data";

export const SocialLinks = () => (
  <>
    {socialLinksData.map((item, index) => {
      return (
        <Link key={"social-link-" + index} href={item.url} isExternal>
          <IconButton
            bgColor="rgm.purple.200"
            color={item.color}
            m={[2, 3]}
            w="80%"
            size="lg"
            aria-label={item.label}
            icon={<item.icon size={30} />}
          />
        </Link>
      );
    })}
  </>
);
