import { pipe, uniq, map, pluck, sortBy, reverse } from "ramda";

import type { Context } from "~/types/context";
import type {
  CategoryFilterData,
  DateFilterData,
  FilterInput,
  FilterOptionItem,
  GeoFilterData,
} from "~/types/filters";
import {
  dateFilters,
  geoFilters,
  categoryFilters,
  dateFilterDataSchema,
  geoFilterDataSchema,
  categoryFilterDataSchema,
} from "~/types/filters";

type Dependencies = Pick<Context, "data" | "user">;

function getItems<T extends Record<string, string>>(
  key: keyof T,
  data: T[],
  labelKey?: keyof T
) {
  return pipe(
    pluck(key as any) as any,
    uniq<string>,
    map<string, FilterOptionItem>((value) => {
      const current = data.find((item) => item[key] === value);

      return {
        parents: current || {},
        label: current && labelKey ? current[labelKey] : value,
        value,
      };
    })
  )(data);
}

function formatFilters<T>(
  fields: string[],
  ...optionItems: FilterOptionItem[][]
) {
  return fields.reduce<T>(
    (acc, key, idx) => ({
      ...acc,
      [key]: {
        name: key,
        selectedValues: [],
        items: optionItems[idx],
      },
    }),
    {} as T
  );
}

export async function getGeoFilters({ data, user }: Dependencies) {
  const geo = await data.query({
    queryName: "filters/geography.sql",
    schema: geoFilterDataSchema,
    params: {
      ...user,
    },
  });

  const countryItems = getItems<GeoFilterData>("countryCode", geo, "country");
  const zoneItems = getItems<GeoFilterData>("zoneCode", geo, "zone");

  return formatFilters<Record<keyof GeoFilterData, FilterInput>>(
    geoFilters,
    zoneItems,
    countryItems
  );
}

const getMonths = pipe(
  getItems<DateFilterData>,
  map<FilterOptionItem, FilterOptionItem>(({ label, value, ...item }) => ({
    label: label.length === 1 ? `0${label}` : label.toString(),
    value: value.length === 1 ? `0${label}` : value.toString(),
    ...item,
  })),
  sortBy<FilterOptionItem>(({ label }) => label),
  reverse<FilterOptionItem>
);

export async function getDateFilters({ data }: Pick<Dependencies, "data">) {
  const dates = await data.query({
    queryName: "filters/date.sql",
    schema: dateFilterDataSchema,
  });

  const yearItems = getItems<DateFilterData>("year", dates);
  const monthItems = getMonths("month", dates);

  return formatFilters<Record<keyof DateFilterData, FilterInput>>(
    dateFilters,
    yearItems,
    monthItems
  );
}

export async function getCategoryFilters({ data, user }: Dependencies) {
  const categories = await data.query<CategoryFilterData>({
    queryName: "filters/category.sql",
    schema: categoryFilterDataSchema,
    params: {
      ...user,
    },
  });

  const axisItems = getItems("axis", categories);
  const subAxisItems = getItems("subAxis", categories);
  const metierItems = getItems("metier", categories);
  const subMetierItems = getItems("subMetier", categories);

  return formatFilters<Record<keyof CategoryFilterData, FilterInput>>(
    categoryFilters,
    axisItems,
    subAxisItems,
    metierItems,
    subMetierItems
  );
}
