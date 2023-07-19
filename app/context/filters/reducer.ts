import type { Reducer } from "react";

import type { FilterState } from "~/types/filters";
import {
  geoFilters,
  dateFilters,
  categoryFilters,
  productFilters,
} from "~/types/filters";
import type { FilterAction } from "./types";

function getDefaultFilter(name: string) {
  return {
    name,
    selectedValues: [],
    items: [],
  };
}

const filters: Array<keyof FilterState> = [
  ...categoryFilters,
  ...productFilters,
  ...geoFilters,
  ...dateFilters,
];

const initialState: FilterState = filters.reduce(
  (acc, name) => ({
    ...acc,
    [name]: getDefaultFilter(name),
  }),
  {} as FilterState
);

export const filterReducer: Reducer<FilterState, FilterAction> = (
  state,
  action
) => {
  switch (action.type) {
    case "set_multiple_filter":
    case "set_single_filter":
      const [key, value] = action.payload;

      return {
        ...state,
        [key]: {
          ...state[key],
          selectedValues: Array.isArray(value) ? value : [value],
        },
      };

    case "reset_all":
      return { ...initialState };

    default:
      return state;
  }
};
