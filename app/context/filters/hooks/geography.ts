import { useMemo } from "react";

import { useFilter } from "~/context/filters/provider";

export function useCountryFilters() {
  const { zone, country } = useFilter();

  return useMemo(() => {
    if (zone.selectedValues.length === 0) {
      return [];
    }

    return country.items.filter(({ parents }) => {
      return parents.zoneCode
        ? zone.selectedValues.includes(parents.zoneCode)
        : true;
    });
  }, [country.items, zone]);
}

export function useGeographyFilters() {
  const { zone } = useFilter();

  return {
    zone: zone.items,
    country: useCountryFilters(),
  };
}
