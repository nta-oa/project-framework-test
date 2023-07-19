import z from "zod";

import type { OptionItem } from "~/components/form/types";

export const geoFilterDataSchema = z.object({
  country: z.string(),
  countryCode: z.string(),
  zone: z.string(),
  zoneCode: z.string(),
});

export type GeoFilterData = z.infer<typeof geoFilterDataSchema>;

export const dateFilterDataSchema = z.object({
  month: z.string(),
  year: z.string(),
});

export type DateFilterData = z.infer<typeof dateFilterDataSchema>;

export const scenarioFilterDataSchema = z.object({
  scenario: z.string(),
});

export type ScenarioFilterData = z.infer<typeof scenarioFilterDataSchema>;

export const categoryFilterDataSchema = z.object({
  axis: z.string(),
  subAxis: z.string(),
  metier: z.string(),
  subMetier: z.string(),
});

export type CategoryFilterData = z.infer<typeof categoryFilterDataSchema>;

export const productFilterDataSchema = z.object({
  signature: z.string(),
  brand: z.string(),
  subBrand: z.string(),
  productName: z.string(),
  productSize: z.string().nullable(),
});

export type ProductFilterData = z.infer<typeof productFilterDataSchema>;

export type FilterOptionItem = OptionItem & {
  parents: {
    year?: string;
    zoneCode?: string;
    axis?: string;
    subaxis?: string;
    metier?: string;
  };
};

export type FilterInput = {
  selectedValues: string[];
  items: FilterOptionItem[];
};

export type FiltersPart<T> = Extract<keyof FilterState, T>[];

export type CategoryKeys = "axis" | "subAxis" | "metier" | "subMetier";
export type ProductKeys =
  | "signature"
  | "brand"
  | "subBrand"
  | "productName"
  | "productSize";
export type DateKeys = "year" | "month";
export type GeoKeys = "zone" | "country";

export type FilterKeys = CategoryKeys | ProductKeys | DateKeys | GeoKeys;

export type FilterState = Record<FilterKeys, FilterInput>;

export const categoryFilters: FiltersPart<CategoryKeys> = [
  "axis",
  "subAxis",
  "metier",
  "subMetier",
];

export const productFilters: FiltersPart<ProductKeys> = [
  "signature",
  "brand",
  "subBrand",
  "productName",
  "productSize",
];

export const dateFilters: FiltersPart<DateKeys> = ["year", "month"];

export const geoFilters: FiltersPart<GeoKeys> = ["zone", "country"];
