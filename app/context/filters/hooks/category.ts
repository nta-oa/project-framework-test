import { useMemo } from "react";

import { useFilter } from "~/context/filters/provider";

export function useSubAxisItems() {
  const { axis, subAxis } = useFilter();

  return useMemo(() => {
    if (axis.selectedValues.length === 0) {
      return [];
    }

    return subAxis.items.filter(({ parents }) => {
      return parents.axis ? axis.selectedValues.includes(parents.axis) : true;
    });
  }, [axis.selectedValues, subAxis.items]);
}

export function useMetierItems() {
  const { subAxis, metier } = useFilter();

  return useMemo(() => {
    if (subAxis.selectedValues.length === 0) {
      return [];
    }

    return metier.items.filter(({ parents }) => {
      return parents.subaxis
        ? subAxis.selectedValues.includes(parents.subaxis)
        : true;
    });
  }, [metier.items, subAxis.selectedValues]);
}

export function useSubMetierItems() {
  const { metier, subMetier } = useFilter();

  return useMemo(() => {
    if (metier.selectedValues.length === 0) {
      return [];
    }

    return subMetier.items.filter(({ parents }) => {
      return parents.metier
        ? metier.selectedValues.includes(parents.metier)
        : true;
    });
  }, [metier.selectedValues, subMetier.items]);
}

export function useCategoryFilters() {
  const { axis } = useFilter();

  return {
    axis: axis.items,
    subAxis: useSubAxisItems(),
    metier: useMetierItems(),
    subMetier: useSubMetierItems(),
  };
}
