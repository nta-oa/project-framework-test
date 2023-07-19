export type navSubMenuType = {
  title: string;
  active: boolean;
  links: navSubMenuLinkType[];
};
export type navSubMenuLinkType = {
  title: string;
  isExternal?: boolean;
  isDisabled?: boolean;
  description?: string;
  url: string;
};
export const navSubMenuData: navSubMenuType[] = [
  {
    title: "SALES PERFORMANCE",
    active: true,
    links: [
      {
        title: "SALES GROWTH ANALYSIS OVERVIEW",
        url: "/",
      },
      {
        title: "SALES GROWTH ANALYSIS RECAP",
        url: "/",
      },
      {
        title: "SALES PHASING REPORT",
        url: "/",
      },
    ],
  },
  {
    title: "VALUE & INFLATION",
    active: true,
    links: [
      {
        title: "VALUE TRACKER",
        url: "/",
      },
      {
        title: "INFLATION TRACKER",
        url: "/",
        isDisabled: true,
      },
      {
        title: "SELLOUT GROWTH REPORT",
        url: "/",
      },
    ],
  },
  {
    title: "MIX & ASSORTMENT",
    active: true,
    links: [
      {
        title: "GROWTH-PROFIT MATRIX",
        url: "/",
      },
      {
        title: "ACTIVE-MIX OVERVIEW",
        url: "/",
      },
      {
        title: "ASSORTMENT MANAGEMENT",
        url: "/",
      },
    ],
  },
  {
    title: "TRADE SPEND MANAGEMENT",
    active: true,
    links: [
      {
        title: "P&L SUMMARY",
        url: "/dashboard/pnl/summary",
      },
      {
        title: "MINORATIONS CASCADING",
        url: "/dashboard/pnl/minorations",
      },
      {
        title: "TRADE TERMS MAPPING",
        url: "/dashboard/pnl/trade-terms",
      },
    ],
  },
  {
    title: "NET PRICE MANAGEMENT",
    active: true,
    links: [
      {
        title: "NET PRICE RECAP",
        url: "/",
      },
      {
        title: "NET PRICE PERFORMANCE",
        url: "/",
      },
      {
        title: "NET PRICE SCATTERING",
        url: "/",
      },
    ],
  },
  {
    title: "SELL-IN & SELLOUT DYNAMICS",
    active: false,
    links: [],
  },
  {
    title: "PERF. vs COMPETITION",
    active: false,
    links: [],
  },
  {
    title: "BRAND PRICING",
    active: true,
    links: [
      {
        title: "RETAIL PRICE RECAP",
        url: "/",
      },
      {
        title: "RETAIL PRICE-TIER OPPORTUNITIES",
        url: "/",
      },
      {
        title: "RETAIL PRICE vs COMPETITION",
        url: "/",
      },
    ],
  },
  {
    title: "PACK-PRICE ARCHITECTURE",
    active: false,
    links: [],
  },
];
