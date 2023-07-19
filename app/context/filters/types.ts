import type { Dispatch } from "react";

import type { FilterState } from "~/types/filters";

export type FilterMultipleAction = {
  type: "set_multiple_filter";
  payload: [keyof FilterState, string[]];
};

export type FilterSingleAction = {
  type: "set_single_filter";
  payload: [keyof FilterState, string];
};

export type FilterEmptyAction = {
  type: "reset_all";
};

export type FilterAction =
  | FilterMultipleAction
  | FilterSingleAction
  | FilterEmptyAction;

export type FilterContextState = FilterState & {
  dispatch: Dispatch<FilterAction>;
};
