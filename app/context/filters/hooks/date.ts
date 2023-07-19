import { useMemo } from "react";

import { useFilter } from "~/context/filters/provider";

export function useMonthItems() {
  const { month, year } = useFilter();

  return useMemo(() => {
    if (year.selectedValues.length === 0) {
      return [];
    }

    return month.items.filter(({ parents }) => {
      return parents.year ? year.selectedValues.includes(parents.year) : true;
    });
  }, [month.items, year.selectedValues]);
}

export function useDateItems() {
  const { year } = useFilter();

  return {
    year: year.items,
    month: useMonthItems(),
  };
}
