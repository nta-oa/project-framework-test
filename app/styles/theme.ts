// theme.ts (tsx file with usage of StyleFunctions, see 4.)
import { extendTheme } from "@chakra-ui/react";

const theme = extendTheme({
  colors: {
    bg: "#E3E3E3",
    header: {
      bg: ["#701f66", "#4b2171"],
    },
    table: {
      header: {
        bg: "#6B007B",
        link: "#FFFFFF",
      },
      arrows: {
        red: "#FF0000",
        green: "#00FF00",
      },
      firstColumnBg: "#E6E6E6",
    },
    button: {
      bg: "rgba(255, 255, 255, 0.3)",
      color: "#FFFFFF",
      hover: {
        bg: "rgba(255, 255, 255, 0.5)",
      },
    },
    rgm: {
      purple: {
        100: "#140c24",
        200: "#30243c",
        300: "#501242",
        400: "#908494",
        500: "#7230C0",
        600: "#23103A",
        700: "#6C047F",
        transparent: "rgba(56, 36, 68, 0.5)",
      },
    },
    social: {
      msteams: "#4d55c0",
      msSharepoint: "#0a7b80",
      support: "#84b5a4",
    },
  },
  variants: {
    "with-rgm-bg": {
      bgGradient:
        "linear(to-tr, rgm.purple.500, rgm.purple.600, rgm.purple.600, rgm.purple.700)",
    },
  },
});

export default theme;
