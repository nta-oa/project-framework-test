import type { ReactNode } from "react";
import { createContext, useReducer, useContext } from "react";

import logger from "~/context/logger";
import type { FilterState } from "~/types/filters";
import { filterReducer } from "./reducer";
import type { FilterContextState } from "./types";

export type FilterProviderProps = { children: ReactNode; value: FilterState };

const FilterContext = createContext({} as FilterContextState);

export function FilterProvider({ children, value }: FilterProviderProps) {
  if (value.year.selectedValues.length === 0) {
    value.year.selectedValues = [value.year.items[0]?.value];
  }

  if (value.month.selectedValues.length === 0) {
    value.month.selectedValues = [value.month.items[0]?.value];
  }

  const [state, dispatch] = useReducer(
    logger<FilterState>(filterReducer, "Filters", "deepSkyBlue"),
    value
  );

  return (
    <FilterContext.Provider value={{ ...state, dispatch }}>
      {children}
    </FilterContext.Provider>
  );
}

export function useFilter() {
  const context = useContext(FilterContext);

  if (context === undefined) {
    throw new Error("useFilter must be used within a FilterProvider");
  }

  return context;
}
